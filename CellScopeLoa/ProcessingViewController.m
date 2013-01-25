//
//  ProcessingViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ProcessingViewController.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "ReviewViewController.h"
#import "ResultsViewController.h"
#import "MainMenuViewController.h"
#import "Analysis.h"
dispatch_queue_t backgroundQueue;

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController
int movieCount;
int numberMovies;
int done=0;

@synthesize urlNum;
@synthesize instructions;
@synthesize program;
@synthesize loaLoaCounter;
@synthesize backImage;
@synthesize resultsImage;
@synthesize progressBar;
@synthesize resultsImageView;

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
    instructions.text = NSLocalizedString(@"PROCESSING",nil);
    backgroundQueue = dispatch_queue_create("edu.berkeley.cellscope.analysisqueue", NULL);
	// Do any additional setup after loading the view
    progressBar.progress = 0.0;
    numberMovies = 0;
    [self processImages];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Results"]) {
        UITabBarController* tc = [segue destinationViewController];
        ReviewViewController* reviewViewController = (ReviewViewController*)[[tc customizableViewControllers] objectAtIndex:0];
        ResultsViewController* resultsViewController = (ResultsViewController*)[[tc customizableViewControllers] objectAtIndex:1];
        reviewViewController.program = program;
        resultsViewController.program = program;
    }
    if([segue.identifier isEqualToString:@"Review"]) {
        MainMenuViewController *menuViewController = [segue destinationViewController];
        menuViewController.managedObjectContext=program.managedObjectContext;
    }
}

- (void)processImages
{
    // Grab the frame record from the Loa program
    NSMutableArray* frameRecord = program.frameRecord;
    NSMutableArray* urls = [[NSMutableArray alloc] init];
    // Get movie URL's from the managed object context
    NSManagedObjectContext* managedObjectContext = program.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    [request setEntity:entity];
    NSString* serial = program.currentSampleSerial;
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"serialnumber LIKE %@", serial];
    [request setPredicate:searchFilter];
    NSError* error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    if(results.count == 0) {
        NSLog(@"Couldn't fetch the sample!");
        NSLog(@"Serial: %@", serial);
    }
    
    urlNum = 0;
    movieCount = 0;
    Sample* sample = [results objectAtIndex:0];
    NSMutableSet* movies = [sample mutableSetValueForKey:@"movies"];
    numberMovies = [movies count];
    NSEnumerator* movieenum = [movies objectEnumerator];
    NSLog(@"Movies: ");
    for(SampleMovie* movie in movieenum) {
        NSLog(@"%@",movie.path);
        NSURL *url = [NSURL URLWithString:movie.path];
        [urls addObject: url];
        movieCount++;
    }

    loaLoaCounter = [[Analysis alloc] init];
    for (id movie in frameRecord) {
        NSMutableArray* framelist = (NSMutableArray*)movie;
    }
        
    dispatch_async(backgroundQueue, ^(void) {
        @autoreleasepool {
            
            [loaLoaCounter analyzeImagesNew:array[urlNum]];
        }
    });
    
        // Register for progress notifications from processing code
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        [[NSNotificationCenter defaultCenter] addObserverForName:@"analysisProgress" object:nil
                                                           queue:mainQueue usingBlock:^(NSNotification *note)
        {
            NSDictionary* userInfo = note.userInfo;
            NSNumber* progress = [userInfo objectForKey:@"progress"];
            NSLog(@"Proc progress: %f", progress.doubleValue);
            NSLog(@"Movie number: %d", urlNum);
            float adjustedprogress = urlNum*(1/(float)numberMovies) + progress.doubleValue*(1/(float)numberMovies);
            progress = [[NSNumber alloc] initWithDouble:adjustedprogress];
            [progressBar setProgress:progress.doubleValue];
            resultsImageView.image = resultsImage;
        }];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(eventHandler:)
         name:@"eventType"
         object:nil ];
    }
}

- (void)eventHandler: (NSNotification *)notification
{
    NSLog(@"notification from analysis");

    resultsImage = [loaLoaCounter getOutImage];
    NSMutableArray* coords = [loaLoaCounter getCoords];
    [coords addObject:array[urlNum]];
    urlNum++;

    [program addMovieFeatures:coords];
    if (movieCount > urlNum){
        //Analysis *loaLoaCounter;
        NSLog(@"Create new loa counter");
        loaLoaCounter=[[Analysis alloc] init];
        dispatch_async(backgroundQueue, ^(void) {
        NSLog(@"moving on to the next URL: %i", urlNum);
            @autoreleasepool {
                [loaLoaCounter analyzeImagesNew:array[urlNum]];
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"urlnum: %d", urlNum);
                NSLog(@"progress at the end: %f", progressBar.progress);
                if(urlNum == numberMovies) {
                    [self performSegueWithIdentifier:@"Results" sender:self];
                }
            });
        });
    }
    else {
        [[NSNotificationCenter defaultCenter]
         removeObserver:self];
        done=1;
        progressBar.progress = 1.0;
    }
}

 
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
