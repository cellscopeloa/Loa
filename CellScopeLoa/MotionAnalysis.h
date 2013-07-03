//
//  MotionAnalysis.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/26/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "ProcessingDelegate.h"

@interface MotionAnalysis : NSObject

@property (strong, nonatomic) NSMutableArray *coordsArray;
@property (strong, nonatomic) NSMutableArray *urls;
@property UIImage *outImage;
@property (strong, nonatomic) NSMutableArray * coordinatesPerMovie;
@property (weak, nonatomic) id<ProcessingDelegate> delegate;

- (id)initWithWidth:(NSInteger)width Height:(NSInteger)height Frames:(NSInteger)frames Movies:(NSInteger)movies Sensitivity:(float)sensitivity;
- (void)writeNextFrame:(CVBufferRef)imageBuffer;
- (void)nextMovie:(NSURL *) url;
- (void)processAllMovies;
- (void)processFramesForMovie:(NSInteger)movidx;
- (void)setProgressWithMovie:(NSInteger)movieIdx Frame:(NSInteger)frameIdx;
@end
