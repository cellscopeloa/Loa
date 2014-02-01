//
//  SampleExporter.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/22/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "SampleExporter.h"
#import "Sample.h"
#import "SampleMovie.h"

@implementation SampleExporter

+ (NSString *) sampleString:(Sample*)sample
{
    NSMutableString* rep = [[NSMutableString alloc] init];
    
    NSString* ser = [NSString stringWithFormat:@"%@", sample.serialnumber];
    NSString* time = [NSString stringWithFormat:@"%@", sample.capturetime];
    NSString* lat = [NSString stringWithFormat:@"%@", sample.lattitude];
    NSString* lon = [NSString stringWithFormat:@"%@", sample.longitude];
    NSString* username = [NSString stringWithFormat:@"%@", sample.username];
    
    [rep appendString:ser];
    [rep appendString:@"\t"];
    [rep appendString:time];
    [rep appendString:@"\t"];
    [rep appendString:lat];
    [rep appendString:@"\t"];
    [rep appendString:lon];
    [rep appendString:@"\t"];
    [rep appendString:username];
    [rep appendString:@"\t"];
    
    int count = 0;
    double nummovies = 0;
    bool allsynced = YES;
    
    NSMutableArray* numberOfWorms = [[NSMutableArray alloc] init];
    for (SampleMovie* movie in sample.movies)
    {
        double coordinateWrites = 5.0;
        double averageFeatures = (double)(movie.features.count) / coordinateWrites;
        count += averageFeatures;
        [numberOfWorms addObject:[NSNumber numberWithDouble:averageFeatures]];
        nummovies += 1;
        if (!(movie.synced)) {
            allsynced = NO;
        }
    }
    
    double fovCount = 5.0;
    double averageWorms = count / fovCount;
    int estimatedCount = (int)(averageWorms / (.00073));
    
    NSString* synced = [NSString stringWithFormat:@"%@", allsynced ? @"YES" : @"NO"];
    [rep appendString:synced];
    [rep appendString:@"\t"];
    
    NSString* mfml = [NSString stringWithFormat:@"%d", estimatedCount];
    
    [rep appendString:mfml];
    [rep appendString:@"\t"];
    
    for (NSNumber* number in numberOfWorms)
    {
        NSString* mf = [NSString stringWithFormat:@"%@", number];
        [rep appendString:mf];
        [rep appendString:@"\t"];
    }
    
    return [NSString stringWithString:rep];
}

+ (NSString*) databaseString:(NSArray*)samples
{
    NSMutableString* rep = [[NSMutableString alloc] init];
    
    [rep appendString:@"Serial"];
    [rep appendString:@"\t"];
    [rep appendString:@"Time"];
    [rep appendString:@"\t"];
    [rep appendString:@"Lattitude"];
    [rep appendString:@"\t"];
    [rep appendString:@"Longitude"];
    [rep appendString:@"\t"];
    [rep appendString:@"Username"];
    [rep appendString:@"\t"];
    [rep appendString:@"Synced"];
    [rep appendString:@"\t"];
    [rep appendString:@"Estimate mf/ml"];
    [rep appendString:@"\t"];
    [rep appendString:@"FOV counts"];
    [rep appendString:@"\n"];
    
    for(Sample* sample in samples)
    {
        [rep appendString:[SampleExporter sampleString:sample]];
        [rep appendString:@"\n"];
    }
    return [NSString stringWithString:rep];
}

@end
