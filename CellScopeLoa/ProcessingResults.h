//
//  ProcessingResults.h
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrameBuffer.h"

@interface ProcessingResults : NSObject

@property (nonatomic, strong) FrameBuffer* frameBuffer;

@property (nonatomic, strong) NSMutableArray* points;
@property (nonatomic, strong) NSMutableArray* startFrames;
@property (nonatomic, strong) NSMutableArray* endFrames;
@property (nonatomic, strong) NSString* sampleSerial;

- (id)initWithFrameBuffer:(FrameBuffer*)buffer andSerial:(NSString*)serial;
- (void)addPoint:(CGPoint)point from:(NSInteger)startFrame to:(NSInteger)endFrame;


@end