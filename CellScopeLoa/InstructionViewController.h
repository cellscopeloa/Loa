//
//  InstructionViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/28/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InstructionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *touchIcon;

@property (weak, nonatomic) IBOutlet UIImageView *instructImage;

@property (weak, nonatomic) IBOutlet UILabel *instructLabel;

@property (strong, nonatomic) NSMutableDictionary *instructSet;

@property (weak, nonatomic) NSString *currentInstruct;

@property (nonatomic) NSInteger instructIdx;

- (IBAction)didTap:(id)sender;

@end
