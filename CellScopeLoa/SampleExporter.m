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
    NSString* synced = [NSString stringWithFormat:@"%@", sample.synced];
    
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
    [rep appendString:synced];
    [rep appendString:@"\t"];
    
    int count = 0;
    double nummovies = 0;
    for (SampleMovie* movie in sample.movies)
    {
        count += movie.numworms.intValue;
        nummovies += 1;
    }
    double avgcount = count/nummovies;
    int estimate = (avgcount / (.00073));
    NSString* mfml = [NSString stringWithFormat:@"%d", estimate];
    
    [rep appendString:mfml];
    [rep appendString:@"\t"];
    
    for (SampleMovie* movie in sample.movies)
    {
        NSString* mf = [NSString stringWithFormat:@"%@", movie.numworms];
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
