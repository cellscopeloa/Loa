//
//  FirstRunViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/20/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstRunViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *deviceIDTextField;
- (IBAction)onDone:(id)sender;

@end
