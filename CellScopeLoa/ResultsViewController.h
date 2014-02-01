//
//  ResultsViewController.h
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"

@interface ResultsViewController : UIViewController <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *sampleIDLabel;

@property UIImage* backImage;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) LoaProgram* program;
@property (weak, nonatomic) IBOutlet UILabel *fieldCountsLabel;

@property (weak, nonatomic) IBOutlet UILabel *wormsField;
@property (strong, nonatomic) NSArray *instructionText;
@property (nonatomic) NSInteger instructIdx;
@property (weak, nonatomic) IBOutlet UITextView *instructions;
@property (strong, nonatomic) IBOutlet UIView *background;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIView *statusBox;

- (void)showResults;
-(void)setupInstructionSet;
- (IBAction)discardPressed:(id)sender;

@end
