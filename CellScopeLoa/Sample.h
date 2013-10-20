//
//  Sample.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/20/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleMovie;

@interface Sample : NSManagedObject

@property (nonatomic, retain) NSDate * capturetime;
@property (nonatomic, retain) NSNumber * lattitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * serialnumber;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSSet *movies;
@end

@interface Sample (CoreDataGeneratedAccessors)

- (void)addMoviesObject:(SampleMovie *)value;
- (void)removeMoviesObject:(SampleMovie *)value;
- (void)addMovies:(NSSet *)values;
- (void)removeMovies:(NSSet *)values;

@end
