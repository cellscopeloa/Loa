//
//  ProcessingResults.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "ProcessingResults.h"
#import "ImageFeature.h"

@implementation ProcessingResults

@synthesize frameBuffer;
@synthesize points;
@synthesize startFrames;
@synthesize endFrames;

- (id)initWithFrameBuffer:(FrameBuffer*)buffer andSerial:(NSString*)serial
{
    self.frameBuffer = buffer;
    self.points = [[NSMutableArray alloc] init];
    self.startFrames = [[NSMutableArray alloc] init];
    self.endFrames = [[NSMutableArray alloc] init];
    self.sampleSerial = serial;
    
    return self;
}

- (id)initWithFrameBuffer:(FrameBuffer *)buffer Serial:(NSString *)serial FeatureSet:(NSSet*)features
{
    self = [self initWithFrameBuffer:buffer andSerial:serial];
    NSArray* allFeatures = [features allObjects];
    for (int i = 0; i < allFeatures.count; i++) {
        ImageFeature* feature = [allFeatures objectAtIndex:i];
        NSNumber* startFrame = feature.startFrame;
        NSNumber* endFrame = feature.endFrame;
        CGPoint loc = CGPointMake(feature.xcoord.intValue, feature.ycoord.intValue);
        [self addPoint:loc from:startFrame.integerValue to:endFrame.integerValue];
    }

    return self;
}

- (void)addPoint:(CGPoint)point from:(NSInteger)startFrame to:(NSInteger)endFrame
{
    [points addObject:[NSValue valueWithCGPoint:point]];
    [startFrames addObject:[NSNumber numberWithInteger:startFrame]];
    [endFrames addObject:[NSNumber numberWithInteger:endFrame]];
}

@end
