//
//  ProcessingViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/16/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessingViewController.h"
#import "ResultsViewController.h"
#import "ProcessingResults.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "ImageFeature.h"

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController

@synthesize program;
@synthesize instructionsView;
@synthesize activityTextLabel;
@synthesize activityView;


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
    instructionsView.text = @"Please wait a moment while the movies are processed.";
    activityView.hidden = FALSE;
    [activityView startAnimating];
    
    activityTextLabel.text = [NSString stringWithFormat:@"Processed %d/%d", program.analysis.resultsList.count, 5];
    // Register processing notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataDownloadComplete:)
                                                 name:@"FrameBufferProcessed" object:nil];
}

- (void)dataDownloadComplete:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        int processedCount = program.analysis.resultsList.count;
        activityTextLabel.text = [NSString stringWithFormat:@"Processed %d/%d", processedCount, 5];
        
        if (program.totalfields == processedCount) {
            [self storeResults];
            [self performSegueWithIdentifier:@"Results" sender:self];
        }
    });
}

- (void)storeResults
{
    NSMutableArray* resultsList = program.analysis.resultsList;
    for (int i = 0; i < resultsList.count; i++) {
        ProcessingResults* result = [resultsList objectAtIndex:i];

        NSString* serial = result.sampleSerial;
        // Pull out the sample with this serial number
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext: program.managedObjectContext];
        [request setEntity:entity];
        
        NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"serialnumber LIKE %@", serial];
        [request setPredicate:searchFilter];
        
        NSError* error;
        NSArray *results = [program.managedObjectContext executeFetchRequest:request error:&error];
        Sample* sample = [results objectAtIndex:0];
        SampleMovie* movie = [sample.movies.allObjects objectAtIndex:i];
        
        NSMutableArray* featureSet = [[NSMutableArray alloc] init];
        // Add new features for all of the points in the results structure
        for (int j = 0; j < result.points.count; j++) {
            NSValue* point = [result.points objectAtIndex:j];
            NSNumber* startFrame = [result.startFrames objectAtIndex:j];
            NSNumber* endFrame = [result.endFrames objectAtIndex:j];
            // Create a new feature
            ImageFeature *feature = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"ImageFeature"
                                     inManagedObjectContext:program.managedObjectContext];
            CGPoint p = point.CGPointValue;
            feature.xcoord = [NSNumber numberWithInt:p.x];
            feature.ycoord = [NSNumber numberWithInt:p.y];
            feature.startFrame = startFrame;
            feature.endFrame = endFrame;
            
            [featureSet addObject:feature];
        }
        
        movie.features = [NSSet setWithArray:featureSet];
    }
    
    [program.managedObjectContext save:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Results"]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        ResultsViewController* viewController = [segue destinationViewController];
        viewController.program = program;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
