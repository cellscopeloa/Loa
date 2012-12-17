//
//  Camera.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "Camera.h"

@implementation Camera

@synthesize movieOutput;
@synthesize progressDelegate;
@synthesize progress;
@synthesize progressTimer;

- (Camera*)init
{
    self = [super init];
    // Setup the AV foundation capture session
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [self.device lockForConfiguration:nil];
    [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Setup output
	self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    
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

@end
