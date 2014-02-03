//
//  CaptureViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>
#import "ProcessingViewController.h"
#import "CaptureViewController.h"
#import "MainMenuViewController.h"
#import "MotionAnalysis.h"
#import "SampleMovie.h"
#import "LoaProgram.h"
#import "FrameBuffer.h"

#define NUMFIELDS 5

@interface CaptureViewController () {
    FrameBuffer* frameBuffer;
    NSInteger frameIndex;
}

@end

@implementation CaptureViewController

@synthesize program;
@synthesize managedObjectContext;

@synthesize session;
@synthesize device;
@synthesize input;
@synthesize output;
@synthesize videoHDOutput;
@synthesize videoPreviewOutput;
@synthesize fieldcounter;
@synthesize captureButton;
@synthesize cancelBarButton;

@synthesize camera;

@synthesize pLayer;
@synthesize busyIndicator;
@synthesize progressBar;
@synthesize instructions;
@synthesize instructionText;
@synthesize instructIdx;


-(void)setupInstructionSet
{
    instructionText = [NSArray arrayWithObjects:
                            NSLocalizedString(@"POSITIONANDFOCUS",nil),
                            NSLocalizedString(@"REPOSITIONANDFOCUS",nil),
                            NSLocalizedString(@"REPOSITIONANDFOCUS",nil),
                            NSLocalizedString(@"REPOSITIONANDFOCUS",nil),
                            NSLocalizedString(@"REPOSITIONANDFOCUS",nil),
                            NSLocalizedString(@"REPOSITIONANDFOCUS",nil), nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    instructions.alpha = 0.0;
    [self setupInstructionSet];
    instructIdx = 0;
    busyIndicator.hidesWhenStopped = YES;
    progressBar.progress = 0.0;
    progressBar.alpha = 0.0;
    captureButton.enabled = NO;
    instructions.text = [instructionText objectAtIndex:instructIdx];
    // fieldcounter.text = [program fovString];
    fieldcounter.text = @"1";
    
    [NSTimer scheduledTimerWithTimeInterval:4.0
                                     target:self
                                   selector:@selector(cameraAvailable)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)cameraAvailable
{
    captureButton.enabled = YES;
}

- (IBAction)focusPressed:(id)sender {
    [self.camera autoFocus];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSInteger frameWidth = 480;
    NSInteger frameHeight = 360;
    // Setup the capture session
    self.camera = [[CaptureCamera alloc] init];
    // Setup the camera
    camera = [[CaptureCamera alloc] initWithWidth:frameWidth Height:frameHeight];
    camera.recordingDelegate = self;
    camera.progressDelegate = self;
    camera.processingDelegate = self;
    [camera setPreviewLayer:pLayer.layer];
    [camera startCamera];
    
    int nframesmax = (int)(5.0*(1/30.0));
    int fov = NUMFIELDS;
    
    // Create a motion analysis object for image processing
    MotionAnalysis* analysis = [[MotionAnalysis alloc] initWithWidth: camera.width
                                                              Height: camera.height
                                                              Frames: nframesmax
                                                              Movies: fov
                                                         Sensitivity: program.sensitivity];
    program.analysis = analysis;
    [UIView animateWithDuration:0.5 animations:^{
        instructions.alpha = 1.0;
    } completion:^(BOOL finished) {
        // pass
    }];
    
    // Execute the next program step, or any setup we need
    if(program.currentSampleSerial == Nil) {
        [program createNewSample];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Stop the camera
    [camera stopCamera];
    camera = nil;
    
    if([segue.identifier isEqualToString:@"Process"]) {
        ProcessingViewController* processingViewController = [segue destinationViewController];
        processingViewController.program = program;
    }
    else if([segue.identifier isEqualToString:@"Cancel"]) {
        MainMenuViewController* mvc = [segue destinationViewController];
        mvc.managedObjectContext = managedObjectContext;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCapture:(id)sender
{
    // Initialize the frame buffer. 5 seconds of video at 30 frames per second.
    int nframes = (int)(5.0/(1/30.0));
    // Drop reference to this frame buffer before creating a new one
    frameBuffer = nil;
    frameBuffer = [[FrameBuffer alloc] initWithWidth:camera.width.integerValue Height:camera.height.integerValue Frames:nframes];
    frameIndex = 0;
    
    // Lock the exposure settings on first run
    if(instructIdx == 0) {
        [camera lockSettings];
    }
    
    [camera captureWithDuration:6.0];
    
    [UIView animateWithDuration:1.0 animations:^{
        instructions.alpha = 0.0;
        progressBar.alpha = 1.0;
        captureButton.enabled = false;
        cancelBarButton.enabled = false;
        
    } completion:^(BOOL finished) {
        // pass
    }];
}

// Frame processing delegate
- (void)processFrame:(CaptureCamera*)sender Buffer:(CVBufferRef)buffer
{
    [frameBuffer writeFrame:buffer atIndex:[NSNumber numberWithInteger:frameIndex]];
    if (frameIndex == 150) {
        NSLog(@"Completed capture");
    }
    frameIndex += 1;
}

- (void)didFinishRecordingFrames:(CaptureCamera*)sender
{
    NSString* currentSampleSerial = program.currentSampleSerial;
    [program.analysis processFrameBuffer:frameBuffer withSerial:currentSampleSerial];
}

- (void)updateProgress:(NSNumber*)progress
{
    progressBar.progress = progress.floatValue;
}

- (void)progressTaskComplete
{
    progressBar.alpha = 0.0;
    [busyIndicator startAnimating];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
    didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    // Store the video in the asset library
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                    completionBlock:^(NSURL *assetURL, NSError *error)
         {
             // Store the video in the program database
             [program movieCapturedWithURL:assetURL];
             
             // Is it time to move on?
             instructIdx++;
             
             // Update the UI
             dispatch_async(dispatch_get_main_queue(), ^{
                 fieldcounter.text = [program fovString];
                 
                 // Stop the busy animations
                 [busyIndicator stopAnimating];
                 progressBar.alpha = 0.0;
                 [UIView animateWithDuration:0.5 animations:^{
                     instructions.alpha = 1.0;
                 } completion:^(BOOL finished) {
                     // pass
                 }];
                 
                 [self checkStatus];
                 instructions.text = [instructionText objectAtIndex:instructIdx];
                 captureButton.enabled = true;
                 cancelBarButton.enabled = true;
             });
         }];
	}
    else
    {
        NSLog(@"Wait! Why not!");
        NSLog(@"%@", outputFileURL);
    }
}

- (void)checkStatus
{
    NSString* status = [program currentStatus];
    if([status isEqualToString:@"Done"]) {
        // Reset the instructions, unlock the camera
        instructIdx = 0;
        [camera unlockSettings];
        [self performSegueWithIdentifier:@"Process" sender:self];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [managedObjectContext reset];
    [self performSegueWithIdentifier:@"Cancel" sender:self];
    [camera stopCamera];
}

-(NSUInteger)supportedInterfaceOrientations
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* tabletMode = (NSNumber*)[defaults objectForKey:@"tabletMode"];
    
    if(tabletMode.boolValue) {
        return UIInterfaceOrientationMaskAll;
    }
    else {
        return UIInterfaceOrientationMaskPortraitUpsideDown;
    }
}

@end
