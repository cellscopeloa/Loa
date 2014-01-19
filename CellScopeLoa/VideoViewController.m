//
//  ReviewVideoViewController.m
//  LoaTestkit
//
//  Created by Matthew Bakalar on 1/10/14.
//  Copyright (c) 2014 Matthew Bakalar. All rights reserved.
//

#import "VideoViewController.h"
#import "ProcessingResults.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoViewController () {
    NSInteger frameNumber;
    NSInteger movieNumber;
    NSTimer* animationTimer;
}

@end

@implementation VideoViewController

@synthesize sample;
@synthesize imageView;
@synthesize circleLayers;
@synthesize currentSampleMovie;
@synthesize reader;
@synthesize frameBuffer;
@synthesize messageLabel;
@synthesize activityView;
@synthesize processingResults;
@synthesize movieNumberLabel;
@synthesize playButton;

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
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    circleLayers = [[NSMutableArray alloc] init];
    NSArray* movies = [sample.movies allObjects];
    currentSampleMovie = [movies objectAtIndex:0];
    // Initialize the view
    [activityView startAnimating];
    movieNumber = 0;
    movieNumberLabel.hidden = YES;
    messageLabel.hidden = YES;
    playButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self loadCurrentMovie];
}

- (void)loadCurrentMovie
{
    // #TODO MHB - hard coded width and height for the video frames
    NSInteger width = (NSInteger) 480;
    NSInteger height = (NSInteger) 360;
    
    // Update the UI stats
    if (animationTimer != nil) {
        [animationTimer invalidate];
    }
    activityView.hidden = NO;
    [activityView startAnimating];
    messageLabel.text = @"Loading video";
    playButton.enabled = NO;
    movieNumberLabel.hidden = YES;
    
    NSNumber* frames = [self countAssetFrames];
    
    // Read in one less frame than the number returned by countframes
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (frameBuffer != nil) {
            [frameBuffer releaseFrameBuffers];
            frameBuffer = nil;
        }
        frameBuffer = [[FrameBuffer alloc] initWithWidth:width Height:height Frames:frames.integerValue];
        [self fillFrameBuffer];
        
        // Initialize the processing results structure
        processingResults = [[ProcessingResults alloc] initWithFrameBuffer:frameBuffer Serial:sample.serialnumber FeatureSet:currentSampleMovie.features];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            messageLabel.hidden = YES;
            [activityView stopAnimating];
            activityView.hidden = YES;
            UIImage* image = [processingResults.frameBuffer getUIImageFromIndex:movieNumber];
            self.imageView.image = [self rotateImage:image];
            movieNumberLabel.text = [NSString stringWithFormat:@"%d", movieNumber];
            movieNumberLabel.hidden = NO;
            playButton.enabled = YES;
        });
    });
}

- (NSNumber*)countAssetFrames
{
    NSURL* currentURL = [NSURL URLWithString:currentSampleMovie.path];
    AVAsset* asset = [AVAsset assetWithURL:currentURL];
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

- (void)fillFrameBuffer
{
    NSURL* currentURL = [NSURL URLWithString:currentSampleMovie.path];
    AVAsset* asset = [AVAsset assetWithURL:currentURL];
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
        if (buffer != NULL)
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

- (void)animateVideo:(NSTimer *)timer
{
    UIImage* image = [processingResults.frameBuffer getUIImageFromIndex:frameNumber];
    self.imageView.image = [self rotateImage:image];
    
    [self clearCircles];
    NSMutableArray* points = processingResults.points;
    NSMutableArray* startFrames = processingResults.startFrames;
    NSMutableArray* endFrames = processingResults.endFrames;
    [self drawCirclesAtCoordinates:points withStartFrames:startFrames endFrames:endFrames forFrameNumber:frameNumber];
    
    frameNumber += 1;
    if (frameNumber == processingResults.frameBuffer.numFrames.integerValue) {
        [animationTimer invalidate];
        playButton.enabled = YES;
    }
}

// Create a UIBezierPath which is a circle at a certain location of a certain radius.
- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:location
                    radius:radius
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    return path;
}

// Create a CAShapeLayer for our circle on tap on the screen
- (void)drawCirclesAtCoordinates:(NSMutableArray*)locations withStartFrames:(NSMutableArray*)startFrames endFrames:(NSMutableArray*)endFrames forFrameNumber:(NSInteger)frame
{
    // Expand position of points to fit the image view
    CGSize imageSize = imageView.frame.size;
    float multiplier = imageSize.width/360.0;
    
    CGFloat circradius = 5.0;
    int i = 0;
    for (NSValue* location in locations) {
        NSNumber* startFrame = (NSNumber*)[startFrames objectAtIndex:i];
        NSNumber* endFrame = (NSNumber*)[endFrames objectAtIndex:i];
        if ((frame > startFrame.integerValue) && (frame <= endFrame.integerValue)) {
            CGPoint point = location.CGPointValue;
            CGPoint rotatedPoint = CGPointMake((360.0-point.y)*multiplier, point.x*multiplier);
            UIBezierPath* path = [self makeCircleAtLocation:rotatedPoint radius:circradius];
            
            // Create new CAShapeLayer
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = path.CGPath;
            shapeLayer.strokeColor = [[UIColor redColor] CGColor];
            shapeLayer.fillColor = nil;
            shapeLayer.lineWidth = 3.0;
            
            [imageView.layer addSublayer:shapeLayer];
            // Save the layer in a list of circleLayers for access later
            [circleLayers addObject:shapeLayer];
        }
        i += 1;
    }
}

// Clear all circle layers from the view and delete them from the circleLayers array
- (void)clearCircles
{
    for (CAShapeLayer* layer in circleLayers) {
        [layer removeFromSuperlayer];
    }
    [circleLayers removeAllObjects];
}

- (IBAction)onNextButtonPressed:(id)sender {
    activityView.hidden = NO;
    [activityView startAnimating];
    messageLabel.text = @"Loading video";
    messageLabel.hidden = NO;
    playButton.enabled = NO;
    movieNumberLabel.hidden = YES;
    
    movieNumber += 1;
    if (movieNumber == 5) {
        movieNumber = 0;
    }
    NSArray* movies = [sample.movies allObjects];
    currentSampleMovie = [movies objectAtIndex:movieNumber];
    [self clearCircles];
    [self loadCurrentMovie];
}

- (IBAction)onPreviousButtonPressed:(id)sender {
    activityView.hidden = NO;
    [activityView startAnimating];
    messageLabel.text = @"Loading video";
    messageLabel.hidden = NO;
    playButton.enabled = NO;
    movieNumberLabel.hidden = YES;
    
    movieNumber -= 1;
    if (movieNumber == -1) {
        movieNumber = 4;
    }
    NSArray* movies = [sample.movies allObjects];
    currentSampleMovie = [movies objectAtIndex:movieNumber];
    [self clearCircles];
    [self loadCurrentMovie];
}

- (IBAction)onPlayButtonPressed:(id)sender
{
    playButton.enabled = NO;
    frameNumber = 0;
    float interval = 1.0/30.0;
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(animateVideo:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (frameBuffer != nil) {
        [frameBuffer releaseFrameBuffers];
        frameBuffer = nil;
    }
}

- (UIImage *)rotateImage:(UIImage*)image
{
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(M_PI/2);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(bitmap, rotatedSize.width, rotatedSize.height);
    CGContextRotateCTM(bitmap, M_PI/2);
    
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width, -image.size.height, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
