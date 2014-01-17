//
//  CaptureCamera.m
//  CellScopeLoa2
//
//  Created by Matthew Bakalar on 1/11/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "CaptureCamera.h"

@implementation CaptureCamera {
    dispatch_queue_t videoQueue; // Queue for processing frames and writing video
    CMTime videoTime;            // Time for video frames
    float captureProgress;
    BOOL writingFrames;
}

// Delegates
@synthesize recordingDelegate;
@synthesize processingDelegate;
@synthesize progressDelegate;

// AVFoundation camera properties
@synthesize assetWriter;
@synthesize assetWriterInput;
@synthesize pixelBufferAdaptor;
@synthesize session;

// Camera state properties
@synthesize temporaryOutputPath;
@synthesize width;
@synthesize height;

- (id)initWithWidth:(NSInteger)frameWidth Height:(NSInteger)frameHeight
{
    self = [super init];
    
    self.width = [NSNumber numberWithInteger:frameWidth];
    self.height = [NSNumber numberWithInteger:frameHeight];
    
    // Initialize the state of the camera
    writingFrames = NO;
    videoQueue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    
    // Setup the AV foundation capture session
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([self.device isFocusModeSupported:AVCaptureFocusModeLocked] ) {
        [self.device lockForConfiguration:nil];
        [self.device setFocusMode:AVCaptureFocusModeLocked];
        [self.device unlockForConfiguration];
    }
    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Setup movie output
    NSDictionary *outputSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:frameWidth], AVVideoWidthKey,
     [NSNumber numberWithInt:frameHeight], AVVideoHeightKey,
     AVVideoCodecH264, AVVideoCodecKey,
     nil];
	self.assetWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType:AVMediaTypeVideo
                             outputSettings:outputSettings];
    /* I'm going to push pixel buffers to it, so will need a
     AVAssetWriterPixelBufferAdaptor, to expect the same 32BGRA input as I've
     asked the AVCaptureVideDataOutput to supply */
    pixelBufferAdaptor =
    [[AVAssetWriterInputPixelBufferAdaptor alloc]
     initWithAssetWriterInput:assetWriterInput
     sourcePixelBufferAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
      kCVPixelBufferPixelFormatTypeKey,
      nil]];
    
    /* We need to warn the input to expect real time data incoming, so that it tries
     to avoid being unavailable at inopportune moments */
    assetWriterInput.expectsMediaDataInRealTime = YES;
    
    // Add session input and output
    [self.session addInput:self.input];
    
    // Setup live processing output
    AVCaptureVideoDataOutput *dataOutput = [AVCaptureVideoDataOutput new];
    dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    [dataOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    if ( [self.session canAddOutput:dataOutput] )
        [self.session addOutput:dataOutput];
    
    AVCaptureConnection *captureConnection = [dataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoOrientationSupported]) {
        [captureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    
    // Setup frame buffer
    [dataOutput setSampleBufferDelegate:self queue:videoQueue];
    
    return self;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Are we recording frames right now?
    if(writingFrames && assetWriterInput.readyForMoreMediaData) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // Send the frame to the processing object
        [processingDelegate processFrame:self Buffer:imageBuffer];
        
        // Pass the frame to the asset writer
        [pixelBufferAdaptor appendPixelBuffer:imageBuffer withPresentationTime:videoTime];
        videoTime.value += 1;
    }
}

- (void)captureWithDuration:(Float32)duration {
    // Start recording
    NSLog(@"Timer starts");
    [self createNewAssetWriterOutputWithCompletionHandler:^{
        
        captureProgress = 0.0;
        
        [NSTimer scheduledTimerWithTimeInterval:duration
                                         target:self
                                       selector:@selector(recordingComplete:)
                                       userInfo:nil
                                        repeats:NO];
        
        [NSTimer scheduledTimerWithTimeInterval:duration/100.0
                                         target:self
                                       selector:@selector(progressClockAction:)
                                       userInfo:nil
                                        repeats:YES];
        writingFrames = YES;
    }];
}

- (void)recordingComplete:(NSTimer *) theTimer
{
    writingFrames = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Timer signals finsihed");
        // Signal to the processing delegate that we are done recording frames
        [processingDelegate didFinishRecordingFrames:self];
    });
    // Let the asset writer finish on his own
    [assetWriter finishWritingWithCompletionHandler:^(){
        // Signal the delegate that recording is complete
        [recordingDelegate captureOutput:nil didFinishRecordingToOutputFileAtURL:temporaryOutputPath fromConnections:nil error:nil];
    }];
}

- (void)progressClockAction:(NSTimer *) theTimer
{
    captureProgress += 0.01;
    [progressDelegate updateProgress:[NSNumber numberWithFloat:captureProgress]];
    if(captureProgress >= 1.0) {
        [theTimer invalidate];
        captureProgress = 0.0;
    }
}

- (void)createNewAssetWriterOutputWithCompletionHandler:(void (^)()) block
{
    /* That's going to go somewhere, I imagine you've got the URL for that sorted,
     so create a suitable asset writer; we'll put our H.264 within the normal
     MPEG4 container */
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.MOV", @"movie", guid];
    
    temporaryOutputPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), uniqueFileName]];
    // Clear temporary movie location
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[temporaryOutputPath relativePath]])
    {
        NSError *error;
        // Remove the old temporary movie
        if ([fileManager removeItemAtPath:[temporaryOutputPath relativePath] error:&error] == NO)
        {
            NSLog(@"Error dealing with this movie path!");
            //Error - handle if requried
        }
    }
    
    self.assetWriter = [[AVAssetWriter alloc]
                        initWithURL:temporaryOutputPath
                        fileType:AVFileTypeMPEG4
                        error:nil];
    [assetWriter addInput:assetWriterInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    videoTime = CMTimeMake(0, 30); // Set timescale at 30 frames per second
    
    if (!block)
        return;
    else
        block();
}

- (void)startCamera
{
    [session startRunning];
}

#pragma mark - Physical settings

- (void)lockSettings
{
    // Lock exposure and white balance
    if ([self.device isExposureModeSupported:AVCaptureExposureModeLocked] ) {
        [self.device lockForConfiguration:nil];
        [self.device setExposureMode:AVCaptureExposureModeLocked];
        [self.device unlockForConfiguration];
    }
    
    if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked] ) {
        [self.device lockForConfiguration:nil];
        [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
        [self.device unlockForConfiguration];
    }
}

- (void)unlockSettings
{
    // Lock exposure and white balance
    if ([self.device isExposureModeSupported:AVCaptureExposureModeLocked] ) {
        [self.device lockForConfiguration:nil];
        [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [self.device unlockForConfiguration];
    }
    
    if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked] ) {
        [self.device lockForConfiguration:nil];
        [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        [self.device unlockForConfiguration];
    }
}

- (void)autoFocus
{
    if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ) {
        [self.device lockForConfiguration:nil];
        [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        [self.device unlockForConfiguration];
        [self.device lockForConfiguration:nil];
        [self.device setFocusMode:AVCaptureFocusModeLocked];
        [self.device unlockForConfiguration];
    }
}

#pragma mark - UI output

- (void)setPreviewLayer:(CALayer*)viewLayer
{
    // Setup image preview layer
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession: self.session];
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureVideoPreviewLayer.frame = viewLayer.bounds;
    NSMutableArray *layers = [NSMutableArray arrayWithArray:viewLayer.sublayers];
    [layers insertObject:captureVideoPreviewLayer atIndex:0];
    viewLayer.sublayers = [NSArray arrayWithArray:layers];
}

@end
