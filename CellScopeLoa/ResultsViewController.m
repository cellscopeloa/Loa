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

#define NUMFOV 5.0

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
@synthesize fieldCountsLabel;

-(void)setupInstructionSet
{
    instructionText = [NSArray arrayWithObjects: @"Test results are displayed below. Press done button to continue.", nil];
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
    float numberoffov = NUMFOV;
    NSArray* movies = [program currentMovies];
    double featureCount = 0;
    NSMutableArray* fovCounts = [[NSMutableArray alloc] init];
    for (SampleMovie* sample in movies) {
        double coordinateWrites = 5.0;
        double averageFeatures = (double)(sample.features.count) / coordinateWrites;
        [fovCounts addObject:[NSNumber numberWithDouble:averageFeatures]];
        featureCount += averageFeatures;
    }
    
    NSMutableString* fovCountsString = [[NSMutableString alloc] init];
    
    for (NSNumber* number in fovCounts) {
        NSString* ser = [NSString stringWithFormat:@"%.1f", number.doubleValue];
        [fovCountsString appendString:ser];
        [fovCountsString appendString:@", "];
    }
    NSString* formattedCountsString = [fovCountsString substringToIndex:fovCountsString.length-2];
    NSLog(@"%@", formattedCountsString);
    
    fieldCountsLabel.text = [NSString stringWithFormat:@"%@", formattedCountsString];
    
    double averageWorms = featureCount / numberoffov;
    int estimatedCount = (int)((featureCount / numberoffov) / (.00073));
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!

    NSString* astr = [formatter stringFromNumber:[NSNumber numberWithFloat:averageWorms]];
    NSString* bstr = [formatter stringFromNumber:[NSNumber numberWithFloat:estimatedCount]];
    
    if(estimatedCount > 30000) {
        statusBox.backgroundColor = [UIColor redColor];
    }
    else {
        statusBox.backgroundColor = [UIColor greenColor];
    }
    countLabel.text = [NSString stringWithFormat:@"%@ mf/ml", bstr];
    wormsField.text = [NSString stringWithFormat:@"%@ mf/field", astr];
    
    // Save the number of worms into the database
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
