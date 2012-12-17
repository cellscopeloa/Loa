//
//  ResultsViewController.h
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"

@interface ResultsViewController : UIViewController

@property UIImage* backImage;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) LoaProgram* program;

@property (strong, nonatomic) NSArray *instructionText;
@property (nonatomic) NSInteger instructIdx;
@property (weak, nonatomic) IBOutlet UITextView *instructions;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

- (void)showResults;
-(void)setupInstructionSet;

@end
