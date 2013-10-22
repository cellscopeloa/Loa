//
//  ProcessingViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ProcessingViewControllerMB.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "ReviewViewController.h"
#import "ResultsViewController.h"
#import "MainMenuViewController.h"
#import "MotionAnalysis.h"

dispatch_queue_t backgroundQueue;

@interface ProcessingViewControllerMB () {
    id progressObserver;
}

@end

@implementation ProcessingViewControllerMB

@synthesize instructions;
@synthesize program;
@synthesize backImage;
@synthesize resultsImage;
@synthesize progressBar;
@synthesize resultsImageView;
@synthesize frameRecord;

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
    backgroundQueue = dispatch_queue_create("edu.berkeley.cellscope.analysisqueue", NULL);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    instructions.text = NSLocalizedString(@"PROCESSING",nil);
	// Do any additional setup after loading the view
    progressBar.progress = 0.0;
    [self processImages];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:progressObserver name:@"analysisProgress" object:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Results"]) {
        ResultsViewController* rvc = [segue destinationViewController];
        rvc.program = program;
    }
    if([segue.identifier isEqualToString:@"Review"]) {
        MainMenuViewController *menuViewController = [segue destinationViewController];
        menuViewController.managedObjectContext=program.managedObjectContext;
    }
}

- (void)processImages
{
    // Register for progress notifications from processing code
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    progressObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"analysisProgress" object:nil
                                                       queue:mainQueue usingBlock:^(NSNotification *note)
     {
         NSDictionary* userInfo = note.userInfo;
         NSNumber* progress = [userInfo objectForKey:@"progress"];
         NSNumber* done = [userInfo objectForKey:@"done"];
         if ([done integerValue] == 1) {
             NSMutableArray *coordinatesPerMovie = [userInfo objectForKey:@"coords"];
             // Write coordinates to database
             // Add results picture to the database
             for(int i=0; i<[coordinatesPerMovie count]; i++) {
                 [program addMovieFeatures:coordinatesPerMovie[i]];
             }
             
             [self performSegueWithIdentifier:@"Results" sender:self];
         }
         else {
             [progressBar setProgress:progress.doubleValue];
             float angleRadians = 90.0 * ((float)M_PI / 180.0f);
             CGAffineTransform rotate = CGAffineTransformMakeRotation(angleRadians);
             [resultsImageView setTransform:rotate];
             resultsImageView.image = resultsImage;
         }
     }];

    MotionAnalysis* analysis = program.analysis;
    analysis.delegate = self;
    dispatch_async(backgroundQueue, ^(void) {
        @autoreleasepool {
            [analysis processAllMovies];
        }
    });
}

- (void)processedMovieResult:(UIImage*)image savedURL:(NSURL*)imageurl movieIndex:(NSNumber*)movidx;
{
    resultsImage = image;
    [program addMovieProcessed:image atURL:imageurl forMovieIndex:movidx];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
