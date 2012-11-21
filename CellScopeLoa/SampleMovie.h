//
//  SampleMovie.h
//  CellScopeLoa
//
//  Created by Mike D'Ambrosio on 11/20/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sample;

@interface SampleMovie : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * numworms;
@property (nonatomic, retain) Sample *sample;
@property (nonatomic, retain) NSSet *wormCoordinates;
@end

@interface SampleMovie (CoreDataGeneratedAccessors)

- (void)addWormCoordinatesObject:(NSManagedObject *)value;
- (void)removeWormCoordinatesObject:(NSManagedObject *)value;
- (void)addWormCoordinates:(NSSet *)values;
- (void)removeWormCoordinates:(NSSet *)values;

@end
