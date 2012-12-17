//
//  ResultsViewController.m
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ResultsViewController.h"
#import "SampleMovie.h"
#import "CaptureViewController.h"

@interface ResultsViewController ()

@end

@implementation ResultsViewController

@synthesize imageView;
@synthesize program;
@synthesize instructIdx;
@synthesize instructionText;
@synthesize instructions;
@synthesize countLabel;

-(void)setupInstructionSet
{
    instructionText = [NSArray arrayWithObjects: @"Test results are displayed below, please consult treatment plan. Press done button to continue.", nil];
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
    [imageView setImage:self.backImage];
	// Do any additional setup after loading the view.
    [self setupInstructionSet];
    instructIdx = 0;
    instructions.text = [instructionText objectAtIndex:instructIdx];
    [self showResults];
}

-(void) viewDidUnload {
    self.backImage=nil;
    [imageView setImage:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"NewTest"]) {
        CaptureViewController* captureViewController = [segue destinationViewController];
        captureViewController.managedObjectContext = program.managedObjectContext;
    }
}

- (void)showResults
{
    NSArray* movies = [program currentMovies];
    int wormcount = 0;
    for (SampleMovie* sample in movies) {
        wormcount += [[sample features] count];
    }
    countLabel.text = [NSString stringWithFormat:@"%d mf/ml", wormcount];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
