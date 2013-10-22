//
//  SampleExporter.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/22/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sample.h"

@interface SampleExporter : NSObject

+ (NSString *) sampleString:(Sample*)sample;
+ (NSString *) databaseString:(NSArray*)samples;

@end
