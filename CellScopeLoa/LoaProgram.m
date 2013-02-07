//
//  LoaProgram.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "LoaProgram.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "ImageFeature.h"

@implementation LoaProgram

@synthesize guided;
@synthesize currentSampleSerial;
@synthesize managedObjectContext;
@synthesize totalfields;
@synthesize fovnumber;
@synthesize samplenumber;
@synthesize frameRecord;
@synthesize analysis;

- (LoaProgram*)initWithMode:(NSString *)guidedMode
{
    self = [super init];
    self.guided = guidedMode;
    samplenumber = 10;
    totalfields = 5;
    fovnumber = 0;
    currentSampleSerial = Nil;
    return self;
}

- (void)createNewSample
{
    Sample* sample = [NSEntityDescription insertNewObjectForEntityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    
    // Setup a new sample with serialnumber equal to the current datetime
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSDate *now = [[NSDate alloc] init];
    NSString *dateString = [format stringFromDate:now];
    
    sample.serialnumber = dateString;
    NSLog(@"Creating with: %@", sample.serialnumber);
    NSError *error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving managed object context: %@", [error localizedDescription]);
    }
    // Hold onto the current sample serial number
    currentSampleSerial = sample.serialnumber;
}

- (void)movieCapturedWithURL:(NSURL*)assetURL
{
    // Store the video in the program database
    SampleMovie *movie = [NSEntityDescription
                          insertNewObjectForEntityForName:@"SampleMovie"
                          inManagedObjectContext:managedObjectContext];
    movie.path = assetURL.absoluteString;
    NSError* error;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving managed object context: %@", [error localizedDescription]);
    }
    // Add the sample movie to the current sample in the database
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    [request setEntity:entity];
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"serialnumber LIKE %@", currentSampleSerial];
    [request setPredicate:searchFilter];
    error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    if(results.count == 0) {
        NSLog(@"Couldn't fetch the sample!");
        NSLog(@"Serial: %@", currentSampleSerial);
    }
    else {
        Sample* sample = [results objectAtIndex:0];
        NSLog(@"Fetched sample: %@", sample.serialnumber);
        [[sample mutableSetValueForKey:@"movies"] addObject:movie];
        NSMutableSet* movies = [sample mutableSetValueForKey:@"movies"];
        NSEnumerator* movieenum = [movies objectEnumerator];
        NSLog(@"Movies: ");
        for( SampleMovie* movie in movieenum) {
            NSLog(@"%@",movie.path);
        }
    }
    fovnumber = fovnumber + 1;
}

- (NSString*)fovString
{
    return [NSString stringWithFormat:@"%d",fovnumber+1];
}

- (NSString*)currentStatus
{
    NSLog(@"Field of view: %d", fovnumber);
    if(fovnumber == 5) {
        NSLog(@"Printing done");
        return @"Done";
    }
    else {
        return @"";
    }
}

- (NSArray*)currentMovies
{
    NSMutableArray* urls = [[NSMutableArray alloc] init];
    // Add the sample movie to the current sample in the database
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    [request setEntity:entity];

    // Pull out the sample with this serial number
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"serialnumber LIKE %@", currentSampleSerial];
    [request setPredicate:searchFilter];

    NSError* error;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    Sample* sample = [results objectAtIndex:0];
    
    NSMutableSet* movies = [sample mutableSetValueForKey:@"movies"];
    NSEnumerator* movieiter = [movies objectEnumerator];
    for( SampleMovie* movie in movieiter) {
        [urls insertObject:movie atIndex:0];
    }
    return urls;
}

- (void)addMovieFeatures:(NSMutableArray *)coordinates
{
    int coordsLength = [coordinates count];
    NSURL * moviePathURL = coordinates[coordsLength-1];
    NSString *moviePath = moviePathURL.absoluteString;
    NSFetchRequest *request2 = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity2 = [NSEntityDescription entityForName:@"SampleMovie" inManagedObjectContext: managedObjectContext];
    [request2 setEntity:entity2];
    // Pull out the movie with this path
    NSPredicate *searchFilter2 = [NSPredicate predicateWithFormat:@"path LIKE %@", moviePath];
    [request2 setPredicate:searchFilter2];
    NSError* error2;
    NSArray *results2 = [managedObjectContext executeFetchRequest:request2 error:&error2];
    SampleMovie* sampleMovie = [results2 objectAtIndex:0];
    int i=0;
    while (i < coordsLength-1) {
        NSLog(@"Add coordinate %d: ", i);
        // Create a new image feature to add to the database
        ImageFeature *feature = [NSEntityDescription
                                 insertNewObjectForEntityForName:@"ImageFeature"
                                 inManagedObjectContext:managedObjectContext];
        feature.samplemovie = sampleMovie;
        //array holds alternating x and y coordinates, last entry is moviepath
        feature.xcoord = coordinates[i];
        i++;
        feature.ycoord = coordinates[i];
        i++;
        [[sampleMovie mutableSetValueForKey:@"features"] addObject:feature];
    }
}

@end
