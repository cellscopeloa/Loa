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
@synthesize sensitivity;
@synthesize locationManager;
@synthesize username;

- (LoaProgram*)initWithMode:(NSString *)guidedMode Sensitivity:(float)sense
{
    self = [super init];
    self.guided = guidedMode;
    self.sensitivity = sense;
    samplenumber = 10;
    totalfields = 3;
    fovnumber = 0;
    currentSampleSerial = Nil;
    [self.locationManager startUpdatingLocation];
    return self;
}

- (void)createNewSample
{
    Sample* sample = [NSEntityDescription insertNewObjectForEntityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    
    // Setup a new sample with serialnumber equal to the current datetime
    // Generate an ID number
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceID = [defaults objectForKey:@"DeviceID"];
    NSNumber *sampleNumber = [defaults objectForKey:@"sampleNumber"];
    NSString* sampleID = [NSString stringWithFormat:@"%@-%05d", deviceID, sampleNumber.intValue];
    // Increment the sample ID number
    [defaults setObject:[NSNumber numberWithInt:(sampleNumber.intValue+1)] forKey:@"sampleNumber"];
    [defaults synchronize];

    sample.synced = [NSNumber numberWithInt:0];
    sample.serialnumber = sampleID;
    //NSLog(@"%@",sample.username);
    sample.username = self.username;
    sample.capturetime = [NSDate date];
    CLLocation* location = [locationManager location];
    if(location == Nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"GPS Error" message: @"Location cannot be saved" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        CLLocationCoordinate2D coordinate = [location coordinate];
        sample.lattitude = [NSNumber numberWithDouble:coordinate.latitude];
        sample.longitude = [NSNumber numberWithDouble:coordinate.longitude];
    }
    
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
    if(fovnumber == 3) {
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

- (void)addMovieProcessed:(UIImage *)processedImage atURL:(NSURL*)url forMovieIndex:(NSNumber*)movidx
{
    
    NSLog(@"Current sample serial: %@", currentSampleSerial);
    
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
    
    NSLog(@"Picked up # samples: %d", [sample.movies count]);
    NSLog(@"Movie index: %d", movidx.integerValue);
    
    NSEnumerator* enumerator = [sample.movies objectEnumerator];
    SampleMovie* samplemovie;
    for(int i=0; i <= movidx.integerValue; i++) {
        samplemovie = (SampleMovie*)[enumerator nextObject];
    }
    
    samplemovie.processedimagepath = [url absoluteString];
    NSLog(@"Picked up samplemovie: %@", samplemovie.path);
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error saving managed object context: %@", [error localizedDescription]);
    }
}

- (CLLocationManager *)locationManager {
    
    if (locationManager != nil) {
        return locationManager;
    }
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.delegate = self;
    
    return locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"Did update location");
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    // Pass
}


@end
