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
#import <AssetsLibrary/AssetsLibrary.h>
#import "MovieProgressDelegate.h"

@class RTPCamera;

@protocol FrameProcessingDelegate

- (void)processFrame:(RTPCamera*)sender Buffer:(CVBufferRef)buffer;  // Frame processing delegate

@end //end protocol

@interface RTPCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoPreviewOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoHDOutput;

@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) id<AVCaptureFileOutputRecordingDelegate> recordingDelegate;
@property (nonatomic, strong) id<MovieProgressDelegate> progressDelegate;
@property (nonatomic, strong) id<FrameProcessingDelegate> processingDelegate;

@property (nonatomic, strong) NSMutableArray *frameList;

@property (nonatomic) Float32 progress;
@property (nonatomic, strong) NSTimer *progressTimer;

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger numberFrames;

- (void)setPreviewLayer:(CALayer*)viewLayer;
- (void)start;
- (IBAction)captureWithDuration:(Float32)duration
                    frameList:(NSMutableArray*)list
              recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate progressDelegate:(id<MovieProgressDelegate>)progressDelegate;
- (void)progressUpdate:(NSTimer*)timer;
- (void)recordingComplete:(NSTimer *)timer;
- (void)createNewAssetWriterOutput;
- (void)lockSettings;
- (void)unlockSettings;
- (void)autoFocus;

@end
