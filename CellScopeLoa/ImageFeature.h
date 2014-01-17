//
//  ImageFeature.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/16/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleMovie;

@interface ImageFeature : NSManagedObject

@property (nonatomic, retain) NSNumber * endFrame;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * startFrame;
@property (nonatomic, retain) NSNumber * xcoord;
@property (nonatomic, retain) NSNumber * ycoord;
@property (nonatomic, retain) SampleMovie *samplemovie;

@end
