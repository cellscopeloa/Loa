//
//  VideoViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/18/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sample.h"
#import "SampleMovie.h"
#import "FrameBuffer.h"
#import "ProcessingResults.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *movieNumberLabel;
@property (nonatomic, strong) Sample* sample;
@property (nonatomic, strong) SampleMovie* currentSampleMovie;
@property (strong, nonatomic) NSMutableArray* circleLayers;
@property (strong, nonatomic) AVAssetReader* reader;
@property (strong, nonatomic) FrameBuffer* frameBuffer;
@property (strong, nonatomic) ProcessingResults* processingResults;
- (IBAction)onNextButtonPressed:(id)sender;
- (IBAction)onPreviousButtonPressed:(id)sender;

- (IBAction)onPlayButtonPressed:(id)sender;
- (UIImage *)rotateImage:(UIImage*)image;

@end
