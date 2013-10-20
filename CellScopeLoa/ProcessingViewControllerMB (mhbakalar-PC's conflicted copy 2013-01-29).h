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

@interface ProcessingViewControllerMB : UIViewController

@property (strong, nonatomic) LoaProgram* program;
@property (strong, nonatomic) MotionAnalysis* analysis;

@property (weak, nonatomic) IBOutlet UITextView *instructions;
@property UIImage* resultsImage;
@property (weak, nonatomic) IBOutlet UIImageView *backImage;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIImageView *resultsImageView;
@property NSMutableArray* frameRecord;

- (IBAction)onPressed:(id)sender;
@end
