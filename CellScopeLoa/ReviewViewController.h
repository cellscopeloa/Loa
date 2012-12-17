//
//  ReviewViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/18/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ReviewViewController : UIViewController

@property (strong, nonatomic) LoaProgram* program;
@property (strong, nonatomic) IBOutlet UIView* mainView;

@property (strong, nonatomic) MPMoviePlayerController* player;

- (void)movieFinishedCallback;

@end