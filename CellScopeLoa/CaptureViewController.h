//
//  CaptureViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Camera.h"
#import "MovieProgressDelegate.h"

@interface CaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate,MovieProgressDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *busyIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) NSArray *instructionText;
@property (nonatomic) NSInteger instructIdx;
@property (weak, nonatomic) IBOutlet UITextView *instructions;
@property (strong, nonatomic) IBOutlet UIView *pLayer;

@property (nonatomic, strong) Camera *camera;
@property (nonatomic) NSInteger isRecording;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMovieFileOutput *output;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoPreviewOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoHDOutput;

- (IBAction)onCapture:(id)sender;

@end
