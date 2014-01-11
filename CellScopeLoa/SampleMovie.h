//
//  SampleMovie.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/11/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ImageFeature, Sample;

@interface SampleMovie : NSManagedObject

@property (nonatomic, retain) NSNumber * numworms;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * processedimagepath;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSSet *features;
@property (nonatomic, retain) Sample *sample;
@end

@interface SampleMovie (CoreDataGeneratedAccessors)

- (void)addFeaturesObject:(ImageFeature *)value;
- (void)removeFeaturesObject:(ImageFeature *)value;
- (void)addFeatures:(NSSet *)values;
- (void)removeFeatures:(NSSet *)values;

@end
