//
//  Camera.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "RTPCamera.h"

@implementation RTPCamera

@synthesize movieOutput;
@synthesize progressDelegate;
@synthesize progress;
@synthesize progressTimer;

- (RTPCamera*)init
{
    self = [super init];
    // Setup the AV foundation capture session
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetLow;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ) {
        [self.device lockForConfiguration:nil];
        [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        [self.device unlockForConfiguration];
    }
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Setup output
	self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    // Setup live processing output
    AVCaptureVideoDataOutput *dataOutput = [AVCaptureVideoDataOutput new];
    dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ( [self.session canAddOutput:dataOutput] )
        [self.session addOutput:dataOutput];
    
    // Setup frame buffer
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [dataOutput setSampleBufferDelegate:self queue:queue];
    
    // Add session input and output
    [self.session addInput:self.input];
    [self.session addOutput:self.movieOutput];
    
    return self;
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
    [self.session startRunning];
}

- (IBAction)captureWithDuration:(Float32)duration recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate progressDelegate:(id<MovieProgressDelegate>)myProgressDelegate{
    
    progress = 0.0;
    progressDelegate = myProgressDelegate;
    [progressDelegate progressUpdate:self.progress];
    
    //Create temporary URL to record to
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        // Remove the old temporary movie
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            //Error - handle if requried
        }
    }
    //Start recording
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
    [self.movieOutput startRecordingToOutputFileURL:outputURL recordingDelegate:delegate];
}

-(void)recordingComplete:(NSTimer *) theTimer
{
    [progressDelegate progressTaskComplete];
    [movieOutput stopRecording];
    [progressTimer invalidate];
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
    CVImageBufferRef imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
    // Let’s lock the buffer base address:
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // Then, let’s extract some useful image information:
    
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    NSLog(@"width: %d", (int)bytesPerRow);
    
    // Remember the video buffer is in YUV format, so I extract the luma component from the buffer in this way:
    
    Pixel_8 *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
}

@end
