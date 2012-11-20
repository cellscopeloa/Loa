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
    [player prepareToPlay];
    [player.view setFrame: mainView.bounds];  // player's frame must match parent's
    [mainView addSubview: player.view];
    
    [player play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
