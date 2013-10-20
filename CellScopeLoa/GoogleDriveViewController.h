//
//  GoogleDriveViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/20/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

@interface GoogleDriveViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) GTLServiceDrive *driveService;

@end
