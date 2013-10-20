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

@interface MotionAnalysis : NSObject

@property NSMutableArray *coordsArray;
@property UIImage *outImage;

- (id)initWithWidth:(NSInteger)width Height:(NSInteger)height Frames:(NSInteger)frames Movies:(NSInteger)movies;
- (void)writeNextFrame:(CVBufferRef)imageBuffer;
- (void)nextMovie;
- (void)processMovies;

@end
