//
//  SampleMovie.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sample;

@interface SampleMovie : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) Sample *sample;

@end
