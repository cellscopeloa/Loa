//
//  AdminViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/18/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import "FrameBuffer.h"
#import "ProcessingResults.h"
#import "Sample.h"

@interface AdminViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, strong) FrameBuffer* frameBuffer;
@property (nonatomic, strong) ProcessingResults* processingResults;
@property (nonatomic, strong) Sample* currentSample;
@property (nonatomic, strong) SampleMovie* currentMovie;
@property (strong, nonatomic) AVAssetReader* reader;

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

@end
