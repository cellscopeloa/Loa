//
//  ProcessingViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"
#import "MotionAnalysis.h"

@interface ProcessingViewControllerMB : UIViewController <ProcessingDelegate>

@property (strong, nonatomic) LoaProgram* program;

@property (weak, nonatomic) IBOutlet UITextView *instructions;
@property UIImage* resultsImage;
@property (weak, nonatomic) IBOutlet UIImageView *backImage;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIImageView *resultsImageView;
@property NSMutableArray* frameRecord;

- (void)processedMovieResult:(UIImage*)image;

- (IBAction)onPressed:(id)sender;
@end
