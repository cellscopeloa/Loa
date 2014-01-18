//
//  AdminViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/18/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "AdminViewController.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "MotionAnalysis.h"
#import "ImageFeature.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface AdminViewController () {
    bool firstrun;
}

@end

@implementation AdminViewController

@synthesize managedObjectContext;
@synthesize locationManager;
@synthesize frameBuffer;
@synthesize processingResults;
@synthesize currentSample;
@synthesize currentMovie;
@synthesize reader;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    firstrun = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    // Do any additional setup after loading the view.
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
    
    imagePicker.allowsEditing = YES;
    if (firstrun) {
        firstrun = NO;
        [self presentViewController:imagePicker
                           animated:YES completion:Nil];
    }
}

- (void)createNewSampleWithMovieAtURL:(NSURL*) sampleURL
{
    Sample* sample = [NSEntityDescription insertNewObjectForEntityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    
    SampleMovie* movie = [NSEntityDescription insertNewObjectForEntityForName:@"SampleMovie" inManagedObjectContext: managedObjectContext];
    movie.path = sampleURL.absoluteString;
    
    // Setup a new sample with serialnumber equal to the current datetime
    // Generate an ID number
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceID = [defaults objectForKey:@"DeviceID"];
    NSNumber *sampleNumber = [defaults objectForKey:@"sampleNumber"];
    NSString* sampleID = [NSString stringWithFormat:@"%@-%05d", deviceID, sampleNumber.intValue];
    // Increment the sample ID number
    [defaults setObject:[NSNumber numberWithInt:(sampleNumber.intValue+1)] forKey:@"sampleNumber"];
    [defaults synchronize];
    
    sample.synced = [NSNumber numberWithBool:NO];
    sample.serialnumber = sampleID;
    //NSLog(@"%@",sample.username);
    sample.username = @"Library";
    sample.capturetime = [NSDate date];
    CLLocation* location = [locationManager location];
    if(location == Nil) {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"GPS Error" message: @"Location cannot be saved" delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
    }
    else {
        CLLocationCoordinate2D coordinate = [location coordinate];
        sample.lattitude = [NSNumber numberWithDouble:coordinate.latitude];
        sample.longitude = [NSNumber numberWithDouble:coordinate.longitude];
    }
    
    // Add the movie to the sample
    NSMutableArray* allMovies = [[NSMutableArray alloc] init];
    [allMovies addObject:movie];
    NSSet* movieSet = [[NSSet alloc] initWithArray:allMovies];
    sample.movies = movieSet;
    
    currentSample = sample;
}

- (void)processMovie
{
    // #TODO MHB - hard coded width and height for the video frames
    NSInteger width = (NSInteger) 480;
    NSInteger height = (NSInteger) 360;
    
    currentMovie = [[currentSample.movies allObjects] objectAtIndex:0];
    NSURL* currentURL = [NSURL URLWithString:currentMovie.path];
    NSNumber* frames = [self countAssetFramesAtURL:currentURL];
    
    // Read in one less frame than the number returned by countframes
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        frameBuffer = [[FrameBuffer alloc] initWithWidth:width Height:height Frames:frames.integerValue];
        [self fillFrameBufferAtURL:currentURL];
        
        // Initialize the processing results structure
        processingResults = [[ProcessingResults alloc] initWithFrameBuffer:frameBuffer andSerial:currentSample.serialnumber];
        
        // Launch processing code on frame structure
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self beginProcessing];
        });
        
    });

}

- (NSNumber*)countAssetFramesAtURL:(NSURL*) assetURL
{
    AVAsset* asset = [AVAsset assetWithURL:assetURL];
    reader = [[AVAssetReader alloc] initWithAsset:asset error:Nil];
    
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack* track = [tracks objectAtIndex:0];
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSNumber* format = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    [dictionary setObject:format forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput* readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:dictionary];
    [reader addOutput:readerOutput];
    [reader startReading];
    
    CMSampleBufferRef buffer;
    
    int i = 0;
    while ([reader status] == AVAssetReaderStatusReading )
    {
        
        buffer=[readerOutput copyNextSampleBuffer];
        if([reader status] == AVAssetReaderStatusReading) {
            i++;
        }
        if (buffer != NULL)
        {
            
            CMSampleBufferInvalidate(buffer);
            CFRelease(buffer);
            buffer = nil;
            //NSLog(@"released buffer");
        }
        
    }
    
    return [[NSNumber alloc] initWithInt:i];
}

- (void)fillFrameBufferAtURL:(NSURL*)assetURL
{
    AVAsset* asset = [AVAsset assetWithURL:assetURL];
    reader = [[AVAssetReader alloc] initWithAsset:asset error:Nil];
    
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack* track = [tracks objectAtIndex:0];
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSNumber* format = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    [dictionary setObject:format forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput* readerOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:dictionary];
    [reader addOutput:readerOutput];
    [reader startReading];
    
    CMSampleBufferRef buffer = nil;
    
    int i = 0;
    while ([reader status] == AVAssetReaderStatusReading )
    {
        if (buffer != nil)
        {
            
            CMSampleBufferInvalidate(buffer);
            CFRelease(buffer);
            buffer = nil;
            //NSLog(@"released buffer");
            
        }
        buffer = [readerOutput copyNextSampleBuffer];
        if([reader status] == AVAssetReaderStatusReading) {
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
            [frameBuffer writeFrame:imageBuffer atIndex:[NSNumber numberWithInt:i]];
            
            i++;
        }
        
        //CFRelease(buffer);
        
    }
    
    //[reader cancelReading];
    //CFRelease(buffer);
    
}

- (void)beginProcessing
{
    MotionAnalysis* analysis = [[MotionAnalysis alloc] initWithWidth: 360
                                                              Height: 480
                                                              Frames: 150
                                                              Movies: 0
                                                         Sensitivity: 1];
    NSMutableArray* coordsArray = [analysis processFramesForMovie:(FrameBuffer *)frameBuffer];
    for (int idx=0; idx+3<[coordsArray count]; idx=idx+4){
        
        NSNumber* pointx= [coordsArray objectAtIndex:(NSInteger)idx];
        NSNumber* pointy= [coordsArray objectAtIndex:(NSInteger)idx+1];
        
        CGPoint point=CGPointMake([pointx floatValue], [pointy floatValue]);
        NSNumber* start= [coordsArray objectAtIndex:(NSInteger)idx+2];
        NSNumber* end= [coordsArray objectAtIndex:(NSInteger)idx+3];
        //NSLog(@"pointx pointy start end %@ %@ %@ %@", pointx, pointy, start, end);
        
        [processingResults addPoint:point from:[start integerValue] to:[end integerValue]];
        
    }
    
    // Do not release the frame buffers yet. ReviewVideoViewController will use them
    //[frameBuffer releaseFrameBuffers];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray* featureSet = [[NSMutableArray alloc] init];
        // Add new features for all of the points in the results structure
        for (int j = 0; j < processingResults.points.count; j++) {
            NSValue* point = [processingResults.points objectAtIndex:j];
            NSNumber* startFrame = [processingResults.startFrames objectAtIndex:j];
            NSNumber* endFrame = [processingResults.endFrames objectAtIndex:j];
            // Create a new feature
            ImageFeature *feature = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"ImageFeature"
                                     inManagedObjectContext:managedObjectContext];
            CGPoint p = point.CGPointValue;
            feature.xcoord = [NSNumber numberWithInt:p.x];
            feature.ycoord = [NSNumber numberWithInt:p.y];
            feature.startFrame = startFrame;
            feature.endFrame = endFrame;
            
            [featureSet addObject:feature];
        }
        
        currentMovie.features = [NSSet setWithArray:featureSet];
        [managedObjectContext save:nil];
        
        [self.navigationController popViewControllerAnimated:YES];
    });
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL* movieURL = [info valueForKey:UIImagePickerControllerMediaURL];
    [self createNewSampleWithMovieAtURL:movieURL];
    [self processMovie];

    [self dismissViewControllerAnimated:YES completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (CLLocationManager *)locationManager {
    
    if (locationManager != nil) {
        return locationManager;
    }
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    return locationManager;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
