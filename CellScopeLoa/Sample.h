//
//  Sample.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SampleMovie;

@interface Sample : NSManagedObject

@property (nonatomic, retain) NSString * serialnumber;
@property (nonatomic, retain) NSSet *movies;
@end

@interface Sample (CoreDataGeneratedAccessors)

- (void)addMoviesObject:(SampleMovie *)value;
- (void)removeMoviesObject:(SampleMovie *)value;
- (void)addMovies:(NSSet *)values;
- (void)removeMovies:(NSSet *)values;

@end
