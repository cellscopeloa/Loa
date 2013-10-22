//
//  SettingsViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 2/7/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsDelegate.h"
#import "MainMenuViewController.h"

@interface SettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISlider *sensitivitySlide;
@property (weak, nonatomic) IBOutlet UILabel *sensitivityIndicator;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet UISwitch *rotateSwitch;

@property (weak, nonatomic) id<SettingsDelegate> delegate;
- (IBAction)onRotateSwitch:(id)sender;

- (IBAction)sensitivityValueChanged:(id)sender;

@end
