//
//  ImageFeature.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 12/14/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleMovie;

@interface ImageFeature : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * xcoord;
@property (nonatomic, retain) NSNumber * ycoord;
@property (nonatomic, retain) SampleMovie *samplemovie;

@end
