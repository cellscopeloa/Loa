//
//  SampleMovie.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 12/14/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ImageFeature, Sample;

@interface SampleMovie : NSManagedObject

@property (nonatomic, retain) NSNumber * numworms;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) Sample *sample;
@property (nonatomic, retain) NSSet *features;
@end

@interface SampleMovie (CoreDataGeneratedAccessors)

- (void)addFeaturesObject:(ImageFeature *)value;
- (void)removeFeaturesObject:(ImageFeature *)value;
- (void)addFeatures:(NSSet *)values;
- (void)removeFeatures:(NSSet *)values;

@end
