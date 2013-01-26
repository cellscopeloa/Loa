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

//@synthesize array;
@synthesize urlNum;
@synthesize instructions;
@synthesize program;
@synthesize loaLoaCounter;
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
    frameRecord = program.frameRecord;
    //NSMutableArray* array = [[NSMutableArray alloc] init];
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
    NSLog(@"number of movies:%i",numberMovies);
    array = [[NSMutableArray alloc] init];
    
    NSEnumerator* movieenum = [movies objectEnumerator];
    NSLog(@"Movies: ");
    for(SampleMovie* movie in movieenum) {
        NSURL *url = [NSURL URLWithString:movie.path];
        NSLog(@"movie path:%@",url);
        
        [array addObject: url];
        movieCount++;
    }
    //NSLog(@"url (very first): %@", [array objectAtIndex:0]);
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(eventHandler:)
     name:@"eventType"
     object:nil ];
    
    /*for (id movie in frameRecord) {
     NSMutableArray* framelist = (NSMutableArray*)movie;
     }
     
     dispatch_async(backgroundQueue, ^(void) {
     @autoreleasepool {
     
     [loaLoaCounter analyzeImagesNew:array[urlNum]];
     }
     });*/
    
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
    NSLog(@"initializing analysis object");
    loaLoaCounter = [[Analysis alloc] init];
    
    
}
//}

- (void)eventHandler: (NSNotification *)notification
{
    NSLog(@"notification from analysis");
    
    //if( ![notification.name isEqualToString:@"initialized"] ){
    if (urlNum>0) {
        
        resultsImage = [loaLoaCounter getOutImage];
        NSMutableArray* coords = [loaLoaCounter getCoords];
        NSLog(@"url: %@", array[urlNum-1]);
        
        [coords addObject:array[urlNum-1]];
        //urlNum++;
        
        [program addMovieFeatures:coords];
        if (urlNum == movieCount){
            //Analysis *loaLoaCounter;
            //NSLog(@"Create new loa counter");
            //loaLoaCounter=[[Analysis alloc] init];
            //dispatch_async(backgroundQueue, ^(void) {
            //    NSLog(@"moving on to the next URL: %i", urlNum-1);
            //    @autoreleasepool {
            //        [loaLoaCounter analyzeImagesNew:array[urlNum-1]];
            //    }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]
                     removeObserver:self];
                    done=1;
                     progressBar.progress = 1.0;
                    NSLog(@"urlnum: %d", urlNum-1);
                    NSLog(@"progress at the end: %f", progressBar.progress);
                        [self performSegueWithIdentifier:@"Results" sender:self];
                });
        //    });
        }
        else {
            //[[NSNotificationCenter defaultCenter]
             //removeObserver:self];
           // done=1;
           // progressBar.progress = 1.0;
        }
    }
    if (done!=1){
        int urlNumAsync=urlNum;
    dispatch_async(backgroundQueue, ^(void) {
        @autoreleasepool {
            
            [loaLoaCounter analyzeImagesFast:array[urlNumAsync]:frameRecord[urlNumAsync]];
        }
    });
    urlNum++;
    }
}
//}


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
