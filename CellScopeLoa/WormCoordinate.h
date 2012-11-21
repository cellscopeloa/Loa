//
//  WormCoordinate.h
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 11/20/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleMovie;

@interface WormCoordinate : NSManagedObject

@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) SampleMovie *movie;

@end
