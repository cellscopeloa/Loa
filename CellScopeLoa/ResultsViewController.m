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
@synthesize sampleIDLabel;

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
        // Save results to the database
        NSError *error;
        if (![program.managedObjectContext save:&error]) {
            NSLog(@"Error saving to managed context");
        }
        CaptureViewController* captureViewController = [segue destinationViewController];
        captureViewController.managedObjectContext = program.managedObjectContext;
    }
    else if([segue.identifier isEqualToString:@"Discard"]) {
        [program.managedObjectContext reset];
        CaptureViewController* captureViewController = [segue destinationViewController];
        captureViewController.managedObjectContext = program.managedObjectContext;
    }
}

- (void)showResults
{
    sampleIDLabel.text = program.currentSampleSerial;
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

- (IBAction)discardPressed:(id)sender {
    [self presentAlertView];
}

- (void)presentAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Discard?" message:@"Are you sure you want to discard the sample?" delegate:nil cancelButtonTitle:@"Discard" otherButtonTitles:nil];
    [alertView addButtonWithTitle:@"Cancel"];
    alertView.delegate = self;
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0) {
        [self performSegueWithIdentifier:@"Discard" sender:self];
    }
    else
    {
        // Pass
    }
}

- (NSUInteger)supportedInterfaceOrientations
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
