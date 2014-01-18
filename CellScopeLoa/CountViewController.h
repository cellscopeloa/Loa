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
@property (weak, nonatomic) IBOutlet UILabel *serialLabel;
@property (strong, nonatomic) IBOutlet UIView *background;
@property (nonatomic, strong) Sample* sample;
@property (weak, nonatomic) IBOutlet UIView *statusBox;

- (void)setupInstructionSet;

@end
