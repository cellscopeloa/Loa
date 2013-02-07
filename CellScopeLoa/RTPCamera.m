//
//  Camera.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "RTPCamera.h"

@implementation RTPCamera {
    CMTime videotime; // Time for video frames
    NSURL* outputPath;  // Temporary URL for storing movies
    dispatch_queue_t queue; // Queue for processing frames and writing video
    BOOL writeout;  // Should we be writing video?
}

@synthesize recordingDelegate;
@synthesize progressDelegate;
@synthesize processingDelegate;
@synthesize progress;
@synthesize progressTimer;
@synthesize assetWriter;
@synthesize assetWriterInput;
@synthesize pixelBufferAdaptor;
@synthesize frameList;
@synthesize width;
@synthesize height;
@synthesize numberFrames;

- (RTPCamera*)init
{
    self = [super init];
    
    writeout = NO;
    // Estimated movie parameters
    width = 480;
    height = 360;
    
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
        [NSNumber numberWithInt:width], AVVideoWidthKey,
        [NSNumber numberWithInt:height], AVVideoHeightKey,
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
	CMTimeShow(captureConnection.videoMinFrameDuration);
	CMTimeShow(captureConnection.videoMaxFrameDuration);
	if (captureConnection.supportsVideoMinFrameDuration)
		captureConnection.videoMinFrameDuration = CMTimeMake(1, 30);
	if (captureConnection.supportsVideoMaxFrameDuration)
		captureConnection.videoMaxFrameDuration = CMTimeMake(1, 30);
    CMTimeShow(captureConnection.videoMinFrameDuration);
    CMTimeShow(captureConnection.videoMaxFrameDuration);
    
    // Setup frame buffer
    queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [dataOutput setSampleBufferDelegate:self queue:queue];

    return self;
}

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

- (void)createNewAssetWriterOutput
{
    /* That's going to go somewhere, I imagine you've got the URL for that sorted,
     so create a suitable asset writer; we'll put our H.264 within the normal
     MPEG4 container */
    
    outputPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"movie.MOV"]];
    // Clear temporary movie location
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[outputPath relativePath]])
    {
        NSLog(@"File exists!");
        NSError *error;
        // Remove the old temporary movie
        if ([fileManager removeItemAtPath:[outputPath relativePath] error:&error] == NO)
        {
            NSLog(@"Error dealing with this movie path!");
            //Error - handle if requried
        }
    }
    
    self.assetWriter = [[AVAssetWriter alloc]
                        initWithURL:outputPath
                        fileType:AVFileTypeMPEG4
                        error:nil];
    [assetWriter addInput:assetWriterInput];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    videotime = CMTimeMake(0, 30); // Set timescale at 30 frames per second
}

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

- (void)start
{
    // Lock focus on bottom left corner
    if ([self.device lockForConfiguration:nil]) {
        CGPoint point;
        point.x = 0;
        point.y = 0;
        // [self.device setFocusPointOfInterest:point];
        // [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    [self.session startRunning];
}

- (IBAction)captureWithDuration:(Float32)duration
                    frameList:(NSMutableArray*)list
              recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate progressDelegate:(id<MovieProgressDelegate>)myProgressDelegate{
    
    progress = 0.0;
    frameList = list;
    progressDelegate = myProgressDelegate;
    recordingDelegate = delegate;
    [progressDelegate progressUpdate:self.progress];
    
    // Start recording
    [self createNewAssetWriterOutput];
    writeout = YES;
    [NSTimer scheduledTimerWithTimeInterval:duration
                                     target:self
                                   selector:@selector(recordingComplete:)
                                   userInfo:nil
                                    repeats:NO];
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:duration/100.0
                                                     target:self
                                                   selector:@selector(progressUpdate:)
                                                   userInfo:nil
                                                    repeats:YES];
}

-(void)recordingComplete:(NSTimer *) theTimer
{
    [progressDelegate progressTaskComplete];
    writeout = NO;
    [assetWriter finishWritingWithCompletionHandler:^(){
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [progressTimer invalidate];
            // Signal the delegate that recording is complete
            [recordingDelegate captureOutput:nil didFinishRecordingToOutputFileAtURL:outputPath fromConnections:nil error:nil];
        }];
    }];
}

-(void)progressUpdate:(NSTimer *)timer
{
    progress += (1.0/100.0);
    [progressDelegate progressUpdate:progress];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Are we recording frames right now?
    if(writeout && assetWriterInput.readyForMoreMediaData) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // Send the frame to the processing object
        [processingDelegate processFrame:self Buffer:imageBuffer];
        
        // Pass the frame to the asset writer
        [pixelBufferAdaptor appendPixelBuffer:imageBuffer withPresentationTime:videotime];
        videotime.value += 1;
    }
}

@end
