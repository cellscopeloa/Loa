//
//  CountViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sample.h"

@interface CountViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *InstructionTextView;
@property (weak, nonatomic) IBOutlet UILabel *wormCountMl;
@property (weak, nonatomic) IBOutlet UILabel *wormCountAbs;
@property (weak, nonatomic) IBOutlet UIView *colorBox;

@property (nonatomic, strong) Sample* sample;

- (void)setupInstructionSet;

@end
