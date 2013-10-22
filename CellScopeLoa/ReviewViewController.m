//
//  ReviewViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/18/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ReviewViewController.h"
#import "SampleMovie.h"

@interface ReviewViewController ()

@end

@implementation ReviewViewController

@synthesize program;
@synthesize player;
@synthesize mainView;

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
    
    NSArray* movies = [program currentMovies];
    SampleMovie* firstmovie = [movies objectAtIndex:0];
    NSURL* url = [NSURL URLWithString:firstmovie.path];
    NSLog(@"URL: %@", firstmovie.path);
    NSLog(@"ToURL: %@", url.absoluteString);
    player = [[MPMoviePlayerController alloc] initWithContentURL: url];
    [player setControlStyle:MPMovieControlStyleNone];
    
    /*
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(movieFinishedCallback:)
     name:MPMoviePlayerPlaybackDidFinishNotification
     object:player];
     */
    [player setScalingMode:MPMovieScalingModeAspectFill];
    [player setFullscreen:FALSE];
    
    //---play partial screen---
    player.view.frame = CGRectMake(0, 44, 320, 367);
    [self.view addSubview:player.view];
    player.shouldAutoplay = NO;
    player.controlStyle = MPMovieControlStyleEmbedded;
    [player prepareToPlay];
    // [player play];
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

- (void)movieFinishedCallback
{
    // Pass
}

@end
