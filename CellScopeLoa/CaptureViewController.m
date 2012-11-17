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
#import "SampleMovie.h"

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
                            NSLocalizedString(@"POSITIONANDFOCUS",nil), nil];
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
    progressBar.alpha = 0.0;
    progressBar.progress = 0.0;
    instructions.text = [instructionText objectAtIndex:instructIdx];
    // fieldcounter.text = [program fovString];
    fieldcounter.text = @"0/3";
}

- (void)viewDidAppear:(BOOL)animated
{
    // Setup the capture session
    self.camera = [[Camera alloc] init];
    [self.camera setPreviewLayer:self.pLayer.layer];
    // Set the camera image alpha to zero while we load
    [self.camera start];
    
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
        processingViewController.program = program;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCapture:(id)sender
{
    [camera captureWithDuration:5.0 recordingDelegate:self progressDelegate:self];
    progressBar.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        instructions.alpha = 0.0;
    } completion:^(BOOL finished) {
        // pass
    }];
}

- (void)progressUpdate:(Float32)progress
{
    progressBar.progress = progress;
}

- (void)progressTaskComplete
{
    progressBar.alpha = 0.1;
    busyIndicator.alpha = 1.0;
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
             
             fieldcounter.text = [program fovString];

             // Stop the busy animations
             progressBar.alpha = 0.0;
             [busyIndicator stopAnimating];
             busyIndicator.alpha = 0.0;
             [UIView animateWithDuration:0.5 animations:^{
                 instructions.alpha = 1.0;
             } completion:^(BOOL finished) {
                 // pass
             }];
             
             // Is it time to move on?
             [self checkStatus];
         }];
	}
}

- (void)checkStatus
{
    NSString* status = [program currentStatus];
    if([status isEqualToString:@"Done"]) {
        [self performSegueWithIdentifier:@"Analyze" sender:self];
    }
}

@end
