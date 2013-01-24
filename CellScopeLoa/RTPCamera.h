//
//  Camera.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MovieProgressDelegate.h"

@interface RTPCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoPreviewOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoHDOutput;

@property (nonatomic, strong) id<AVCaptureFileOutputRecordingDelegate> recordingDelegate;
@property (nonatomic, strong) id<MovieProgressDelegate> progressDelegate;

@property (nonatomic) NSInteger isRecording;
@property (nonatomic) Float32 progress;
@property (nonatomic, strong) NSTimer *progressTimer;

- (void)setPreviewLayer:(CALayer*)viewLayer;
- (void)start;
- (IBAction)captureWithDuration:(Float32)duration recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate progressDelegate:(id<MovieProgressDelegate>)progressDelegate;
-(void)progressUpdate:(NSTimer*)timer;
-(void)recordingComplete:(NSTimer *)timer;

@end
