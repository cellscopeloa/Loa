//
//  DataTableViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

@interface DataTableViewController : UITableViewController <UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginButton;

@property (nonatomic, strong) NSNumber* lastSelectedIndex;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSArray* samples;
@property (nonatomic, strong) GTLServiceDrive *driveService;
- (IBAction)loginButtonPressed:(id)sender;

- (IBAction)onExport:(id)sender;

- (IBAction)donePressed:(id)sender;

@end
