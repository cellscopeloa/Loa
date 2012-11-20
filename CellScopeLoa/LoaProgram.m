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

@implementation LoaProgram

@synthesize guided;
@synthesize currentSampleSerial;
@synthesize managedObjectContext;
@synthesize totalfields;
@synthesize fovnumber;

- (LoaProgram*)initWithMode:(NSString *)guidedMode
{
    self = [super init];
    self.guided = guidedMode;
    self.samplenumber = 10;
    totalfields = 3;
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
    self.fovnumber = self.fovnumber + 1;
}

- (NSString*)fovString
{
    return [NSString stringWithFormat:@"%d/%d",fovnumber,totalfields];
}

- (NSString*)currentStatus
{
    /*
    NSLog(@"Field of view: %d", self.fovnumber);
    if(self.fovnumber == 3) {
        return @"Done";
    }
    else {
        return @"";
    }
     */
    return @"Done";
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

@end
