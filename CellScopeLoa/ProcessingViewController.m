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
#import "MainMenuViewController.h"
#import "Analysis.h"
dispatch_queue_t backgroundQueue;

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController
int movieCount;
int done=0;
@synthesize urlNum;
@synthesize instructions;
@synthesize program;
@synthesize loaLoaCounter;
@synthesize backImage;
@synthesize resultsImage;

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
    [self processImages];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Analyze"]) {
        ReviewViewController* reviewViewController = segue.destinationViewController;
        reviewViewController.program = program;
    }
    if([segue.identifier isEqualToString:@"Review"]) {
        MainMenuViewController *menuViewController = [segue destinationViewController];
        menuViewController.managedObjectContext=program.managedObjectContext;
    }
}

- (void)processImages
{
    
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
    else {
        Sample* sample = [results objectAtIndex:0];
        NSMutableSet* movies = [sample mutableSetValueForKey:@"movies"];
        NSEnumerator* movieenum = [movies objectEnumerator];
        NSLog(@"Movies: ");
        urlNum=0;
        movieCount=0;
        //Analysis *loaLoaCounter;

        loaLoaCounter=[[Analysis alloc] init];
        array = [[NSMutableArray alloc] init];
        for( SampleMovie* movie in movieenum) {
            NSLog(@"%@",movie.path);
            NSURL *url = [NSURL URLWithString:movie.path];
            //[loaLoaCounter addURL:url];
            [array addObject: url];
            movieCount++;
        }
        
        dispatch_async(backgroundQueue, ^(void) {
            @autoreleasepool {
            [loaLoaCounter analyzeImagesNew:array[urlNum]];
            }
        });
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(eventHandler:)
         name:@"eventType"
         object:nil ];
    }
}

-(void)eventHandler: (NSNotification *) notification
{
    NSLog(@"notification from analysis");

    self.resultsImage=[loaLoaCounter getOutImage];

    NSMutableArray * coords=[loaLoaCounter getCoords];
    [coords addObject:array[urlNum]];
    urlNum++;

    [program wormCoordinatesAdd:coords];
    if (movieCount>urlNum){
        //Analysis *loaLoaCounter;
        loaLoaCounter=[[Analysis alloc] init];
        dispatch_async(backgroundQueue, ^(void) {
        NSLog(@"%i",urlNum);
            @autoreleasepool {
                [loaLoaCounter analyzeImagesNew:array[urlNum]];
            }
        });
    }
    else {
        [[NSNotificationCenter defaultCenter]
         removeObserver:self];
        done=1;
    }
    [backImage performSelectorOnMainThread:@selector(setImage:) withObject: resultsImage waitUntilDone:YES];

}

 
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPressed:(id)sender {
    if (done==1)
    [self performSegueWithIdentifier:@"Review" sender:self];
}
@end
