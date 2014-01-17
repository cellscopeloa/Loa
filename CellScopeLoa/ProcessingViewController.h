//
//  ProcessingViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/16/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"

@interface ProcessingViewController : UIViewController

@property (strong, nonatomic) LoaProgram* program;
@property (weak, nonatomic) IBOutlet UITextView *instructionsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UILabel *activityTextLabel;

- (void) dataDownloadComplete:(NSNotification *)notif;

@end
