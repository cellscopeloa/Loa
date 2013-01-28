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

@interface ProcessingViewControllerMB ()

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
    instructions.text = NSLocalizedString(@"PROCESSING",nil);
    backgroundQueue = dispatch_queue_create("edu.berkeley.cellscope.analysisqueue", NULL);
	// Do any additional setup after loading the view
    progressBar.progress = 0.0;
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
    // Register for progress notifications from processing code
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"analysisProgress" object:nil
                                                       queue:mainQueue usingBlock:^(NSNotification *note)
     {
         NSDictionary* userInfo = note.userInfo;
         NSNumber* progress = [userInfo objectForKey:@"progress"];
         NSNumber* done = [userInfo objectForKey:@"done"];
         if ([done integerValue] == 1) {
             [self performSegueWithIdentifier:@"Results" sender:self];
         }
         else {
             [progressBar setProgress:progress.doubleValue];
             resultsImageView.image = resultsImage;
         }
     }];

    MotionAnalysis* analysis = program.analysis;
    dispatch_async(backgroundQueue, ^(void) {
        @autoreleasepool {
            [analysis processAllMovies];
        }
    });
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
