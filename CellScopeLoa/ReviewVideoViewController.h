//
//  ReviewVideoViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoaProgram.h"

@interface ReviewVideoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) LoaProgram* program;

@end
