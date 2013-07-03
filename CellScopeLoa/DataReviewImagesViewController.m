//
//  DataReviewImagesViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "DataReviewImagesViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SampleMovie.h"

@interface DataReviewImagesViewController () {
    int frameNumber;
    int framesLeft;
    CGRect scrollFrame;
    NSEnumerator* enumerator;
    NSArray* movieSamples;
}

@end

@implementation DataReviewImagesViewController

@synthesize sample;
@synthesize scrollView;
@synthesize baseView;
@synthesize pageControl;
@synthesize infoTextView;

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
    self.scrollView.delegate = self;
    movieSamples = [sample.movies allObjects];
    // Update the count
    int featureCount = [[[movieSamples objectAtIndex:0] features] count];
    infoTextView.text = [[NSString alloc] initWithFormat:@"Count: %d", featureCount];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect myScrollFrame;
    myScrollFrame.origin = self.scrollView.frame.origin;
    myScrollFrame.size = self.scrollView.frame.size;
    scrollFrame = myScrollFrame;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [sample.movies count], self.scrollView.frame.size.height);
    
    frameNumber = 0;
    framesLeft = sample.movies.count-1;
    enumerator = [movieSamples objectEnumerator];

    [self loadNextPhoto];
}

- (void)loadNextPhoto
{
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        // Prepare frame
        CGRect frame;
        frame.origin.x = scrollFrame.size.width * 0.5 * frameNumber;
        NSLog(@"frame number here: %d", frameNumber);
        frame.origin.y = 0;
        frame.size = self.scrollView.frame.size;
        
        UIView *subview = [[UIView alloc] initWithFrame:frame];
        [self.scrollView insertSubview:subview atIndex:0];
        
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref];

            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            imageView.image = image;
            float angleRadians = 90.0 * ((float)M_PI / 180.0f);
            CGAffineTransform rotate = CGAffineTransformMakeRotation(angleRadians);
            [imageView setTransform:rotate];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [subview performSelectorOnMainThread:@selector(addSubview:) withObject:imageView waitUntilDone:true];
        }
        
        if(framesLeft != 0) {
            framesLeft -= 1;
            frameNumber += 1;
            [self performSelectorOnMainThread:@selector(loadNextPhoto)
                                   withObject:nil
                                waitUntilDone:true];
        }
        
    };
    
    // Image retreival recursion
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"Cant get image - %@",[myerror localizedDescription]);
    };
    
    // Launch image retreival recursion
    SampleMovie* movie = [enumerator nextObject];
    NSURL *asseturl = [NSURL URLWithString: movie.processedimagepath];
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:asseturl
                   resultBlock:resultblock
                  failureBlock:failureblock];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
    // Update the count
    int featureCount = [[[movieSamples objectAtIndex:page] features] count];
    infoTextView.text = [[NSString alloc] initWithFormat:@"Count: %d", featureCount];
}


@end
