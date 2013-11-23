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

@interface CaptureViewController ()

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

@synthesize frameRecord;

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
    // Setup the capture session
    self.camera = [[RTPCamera alloc] init];
    [self.camera setPreviewLayer:self.pLayer.layer];
    
    // Set the processing delegate
    self.camera.processingDelegate = self;
    // Set the camera image alpha to zero while we load
    [self.camera start];
    
    int nframesmax = 200;
    int fov = 3;
    
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
    if([segue.identifier isEqualToString:@"Analyze"]) {
        ProcessingViewController* processingViewController = [segue destinationViewController];
        program.frameRecord = frameRecord;
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
    NSMutableArray* frames = [[NSMutableArray alloc] init];
    [frameRecord addObject:frames];
    
    // Lock the exposure settings on first run
    if(instructIdx == 0) {
        [camera lockSettings];
    }
    
    [camera captureWithDuration:5.0 frameList:frames recordingDelegate:self progressDelegate:self];
    
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
- (void)processFrame:(RTPCamera*)sender Buffer:(CVBufferRef)buffer
{
    [program.analysis writeNextFrame:buffer];
}

- (void)progressUpdate:(Float32)progress
{
    progressBar.progress = progress;
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
    NSLog(@"Storing video in the asset library...");
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                    completionBlock:^(NSURL *assetURL, NSError *error)
         {
             // Store the video in the program database
             [program movieCapturedWithURL:assetURL];
             
             fieldcounter.text = [program fovString];

             // Stop the busy animations
             [busyIndicator stopAnimating];
             progressBar.alpha = 0.0;
             [UIView animateWithDuration:0.5 animations:^{
                 instructions.alpha = 1.0;
             } completion:^(BOOL finished) {
                 // pass
             }];
             
             // Advance the analysis movie counter
             [program.analysis nextMovie:assetURL];
             
             // Is it time to move on?
             instructIdx++;
             [self checkStatus];
             instructions.text = [instructionText objectAtIndex:instructIdx];
             captureButton.enabled = true;
             cancelBarButton.enabled = true;
         }];
	}
}

- (void)checkStatus
{
    NSString* status = [program currentStatus];
    NSLog(@"Current status: ");
    if([status isEqualToString:@"Done"]) {
        // Reset the instructions, unlock the camera
        instructIdx = 0;
        [camera unlockSettings];
        [self performSegueWithIdentifier:@"Analyze" sender:self];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [managedObjectContext reset];
    [self performSegueWithIdentifier:@"Cancel" sender:self];
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
