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
@synthesize statusBox;
@synthesize background;
@synthesize countLabel;
@synthesize wormsField;

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
    float numberoffov = 3.0;
    NSArray* movies = [program currentMovies];
    int wormcount = 0;
    for (SampleMovie* sample in movies) {
        wormcount += [[sample features] count];
    }
    double avg_worms = wormcount/numberoffov;
    int estimated_count = ((wormcount / numberoffov) / (.00073));
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!

    NSString* astr = [formatter stringFromNumber:[NSNumber numberWithFloat:avg_worms]];
    NSString* bstr = [formatter stringFromNumber:[NSNumber numberWithFloat:estimated_count]];
    
    if(estimated_count > 30000) {
        statusBox.backgroundColor = [UIColor redColor];
    }
    else {
        statusBox.backgroundColor = [UIColor greenColor];
    }
    countLabel.text = [NSString stringWithFormat:@"%@ mf/ml", bstr];
    wormsField.text = [NSString stringWithFormat:@"%@ mf/field", astr];
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
