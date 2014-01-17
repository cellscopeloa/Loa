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
#import "FrameBuffer.h"

@interface MotionAnalysis : NSObject

// MHB Properties
@property (strong, nonatomic) NSMutableArray* frameBufferList;
@property (strong, nonatomic) NSMutableArray* resultsList;

@property (strong, nonatomic) NSMutableArray *coordsArray;
@property (strong, nonatomic) NSMutableArray *tempCoordsArray;

@property (strong, nonatomic) NSMutableArray *urls;
@property UIImage *outImage;
@property (strong, nonatomic) NSMutableArray * coordinatesPerMovie;
//@property (weak, nonatomic) id<ProcessingDelegate> delegate;

- (id)initWithWidth:(NSInteger)width Height:(NSInteger)height Frames:(NSInteger)frames Movies:(NSInteger)movies Sensitivity:(float)sensitivity;

- (NSMutableArray *)processFramesForMovie:(FrameBuffer*)frameBuffer;  // Mike D method

- (void)processFrameBuffer:(FrameBuffer*)frameBuffer withSerial:(NSString*)serial;  // Matt B organizing method

@end
