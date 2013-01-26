//
//  Analysis.m
//  LoaLoaAugust
//
//  Created by Mike D'Ambrosio on 9/4/12.
//  Copyright (c) 2012 Mike D'Ambrosio. All rights reserved.
//


#import "Analysis.h"
#import "UIImage+OpenCV.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@implementation Analysis
UIImage *outImagebwopen;
int numContoursLast=1;
int movieNum=0;
@synthesize asset;
@synthesize generator;
@synthesize coordsArray;
@synthesize progress;

-(id)init
{
    self=[super init];
    if (self!=nil){
        array = [[NSMutableArray alloc] init];
        coordsArray = [[NSMutableArray alloc] init];
        progress = [[NSNumber alloc] initWithDouble:0.0];
    }
    NSLog(@"sending initialization message from analysis");
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"eventType"
     object:nil ];

    return self;
    

}
-(UIImage *)generateImage:(int) frame
{
    UIImage * retImg;
    CMTime thumbTime = CMTimeMake(frame+15,30);
    //NSLog(@"%lld", thumbTime.value);
    NSError *err = NULL;
    CGImage * im=[generator copyCGImageAtTime:thumbTime actualTime:NULL error:&err];
    retImg=[UIImage imageWithCGImage:im];
    CGImageRelease(im);
    //NSLog(@"%i", i);
    return retImg;
}

-(void)addURL: (NSURL*) url{
    [array addObject: url];
}
-(void)startAnalysis {
    if ([array count]>movieNum){
        NSURL*url=[array objectAtIndex:(NSUInteger)movieNum];
        movieNum++;
        [self analyzeImagesNew:url];
    }
}
-(void) setupGenerator{
    asset=[[AVURLAsset alloc] initWithURL:self.movieURL options:nil];
    generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    //reverse for non-converted video (270,480)
    CGSize maxSize = CGSizeMake(270, 480);
    generator.maximumSize = maxSize;
    generator.requestedTimeToleranceBefore=kCMTimeZero;
    generator.requestedTimeToleranceAfter=kCMTimeZero;
    
}


-(void) analyzeImagesNew: (NSURL *)movieURL {
    self.movieURL = movieURL;
    [self setupGenerator];
    //first, average and convolve the images;
    int sz[3] = {480,270,3};
    cv::Mat outImage(3,sz, CV_16UC(1), cv::Scalar::all(0));
    cv::Mat kernel = cv::Mat::ones(3, 3, CV_32F);
    cv::Mat kernel2 = cv::Mat::ones(12, 12, CV_32F);
    cv::Mat kernel3 = cv::Mat::ones(50,50,CV_32F);
    cv::Mat movieFrameMatOld;
    cv::Mat movieFrameMatCum;
    cv::Mat movieFrameMatFirst;
    cv::Mat movieFrameMatDiff;
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat;
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNorm(480,270, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatNormOld;
    cv::Mat foundWorms(480,270, CV_8UC1, cv::Scalar::all(0));
    int i=1;
    int frame=1;
    int skip=2;
    int aveFrames=30/skip;
    while(i<100/skip) {
        while(i<=aveFrames) {
            UIImage * test= [self generateImage:(frame-1)];
            
            // Post notification about analysis progress
            // 80% of progress is loading videos
            // 3 total videos for now
            float newprogress = progress.doubleValue + (1/27.0)*(1/2.0);
            NSLog(@"newprogress: %f", newprogress);
            //if (newprogress > progress.doubleValue) {
            progress = [NSNumber numberWithDouble:newprogress];
            NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", nil];
            NSArray* objects = [[NSArray alloc] initWithObjects:progress, nil];
            NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
            //}
            
            NSLog(@"gen image: %i",frame);
            movieFrameMat= [test CVMat];
            test=nil;
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            cv::filter2D(movieFrameMat, movieFrameMat,-1,kernel,cv::Point(-1,-1));
            
            if (i==1){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                movieFrameMatCum=movieFrameMatOld+movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=cv::Mat();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            i=i+1;
            frame=frame+skip;
        }
        if (i==(aveFrames+1)){
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            //filter2D(movieFrameMatNorm, movieFrameMatNorm, -1 , kernel, cv::Point( -1, -1 ), 0, cv::BORDER_DEFAULT );
        }
        if (i>aveFrames+1) {
            UIImage * test= [self generateImage:(frame-1)];
            movieFrameMat= [test CVMat];
            test=nil;
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            cv::filter2D(movieFrameMat, movieFrameMat,-1,kernel,cv::Point(-1,-1));
            
            UIImage * test2= [self generateImage:(frame-aveFrames+1)];
            movieFrameMatFirst= [test2 CVMat];
            test2=nil;
            cv::cvtColor(movieFrameMatFirst, movieFrameMatFirst, CV_RGB2GRAY);
            
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMatFirst, movieFrameMatFirst);
            movieFrameMatFirst.convertTo(movieFrameMatFirst, CV_16UC1);
            cv::filter2D(movieFrameMatFirst, movieFrameMatFirst,-1,kernel,cv::Point(-1,-1));
            
            movieFrameMatCum=movieFrameMatCum-movieFrameMatFirst + movieFrameMat;
            movieFrameMat.release();
            movieFrameMat=cv::Mat();
            movieFrameMatFirst.release();
            movieFrameMatFirst=cv::Mat();
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            //cv::filter2D(movieFrameMatNorm, movieFrameMatNorm,-1,kernel,cv::Point(-1,-1));
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            movieFrameMatNormOld.release();
            movieFrameMatNormOld=cv::Mat();
            if (i==aveFrames+2){
                movieFrameMatDiff=movieFrameMatDiffTmp;
            }
            else {
                movieFrameMatDiff=movieFrameMatDiff+movieFrameMatDiffTmp;
            }
            movieFrameMatDiffTmp.release();
            movieFrameMatDiffTmp=cv::Mat();
        }
        movieFrameMatNormOld=movieFrameMatNorm.clone();
        movieFrameMatNorm.release();
        movieFrameMatNorm=cv::Mat();
        frame=frame+skip;
        i=i+1;
        
        // Post notification about analysis progress
        // 80% of progress is loading videos
        // 3 total videos for now
        float newprogress = progress.doubleValue + (1/33.0)*(1/2.0);
        NSLog(@"newprogress: %f", newprogress);
        //if (newprogress > progress.doubleValue) {
        progress = [NSNumber numberWithDouble:newprogress];
        NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", nil];
        NSArray* objects = [[NSArray alloc] initWithObjects:progress, nil];
        NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
        //}
        
        NSLog(@"Difference progress: %d", i);
    }
    cv::Mat movieFrameMatBack;
    
    //cv::Mat_<double>gk(49,49);
    //gk=cv::getGaussianKernel(2500,10,CV_32F);
    //cv::filter2D(movieFrameMatDiff, movieFrameMatBack,-1,gk,cv::Point(-1,-1));
    cv::Size ksize(49,49);
    //cv::GaussianBlur(movieFrameMatDiff,movieFrameMatBack, ksize, .5, 0, cv::BORDER_DEFAULT);
    
    //movieFrameMatDiff=movieFrameMatDiff-movieFrameMatBack;
    
    movieFrameMatDiffOrig = movieFrameMatDiff.clone();
    cv::Scalar imageAve = cv::mean(movieFrameMatDiffOrig);
    NSLog(@"img avg: %f",imageAve.val[0]);
    
    bool findinWorms=TRUE;
    while(findinWorms==TRUE) {
        cv::Mat findinWormsConv;
        cv::filter2D(movieFrameMatDiff, findinWormsConv,-1,kernel2,cv::Point(-1,-1));
        double maxVal;
        int maxIdx[2] = {255, 255};
        minMaxIdx(findinWormsConv, 0, &maxVal, 0, maxIdx);
        NSLog(@"img max: %f",maxVal);
        NSLog(@"max x: %i",maxIdx[0]);
        NSLog(@"max y: %i",maxIdx[1]);
        
        if (maxVal > (imageAve.val[0]*266)){
            
            int col=floor(maxIdx[1]);
            int row=maxIdx[0];
            int colRangeLow=0;
            int colRangeHigh=0;
            int rowRangeLow=0;
            int rowRangeHigh=0;
            if (col<25){
                colRangeLow=0;
            }
            else {
                colRangeLow=col-25;
            }
            if (col>(movieFrameMatDiff.cols-25)){
                colRangeHigh=movieFrameMatDiff.cols;
            }
            else {
                colRangeHigh=col+25;
            }
            
            if (row<25){
                rowRangeLow=0;
            }
            else {
                rowRangeLow=row-25;
            }
            if (row>(movieFrameMatDiff.rows-25)){
                rowRangeHigh=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHigh=row+25;
            }
            
            col=floor(maxIdx[1]);
            row=maxIdx[0];
            int colRangeLowS=0;
            int colRangeHighS=0;
            int rowRangeLowS=0;
            int rowRangeHighS=0;
            if (col<10){
                colRangeLowS=0;
            }
            else {
                colRangeLowS=col-10;
            }
            if (col>(movieFrameMatDiff.cols-10)){
                colRangeHighS=movieFrameMatDiff.cols;
            }
            else {
                colRangeHighS=col+10;
            }
            
            if (row<10){
                rowRangeLowS=0;
            }
            else {
                rowRangeLowS=row-10;
            }
            if (row>(movieFrameMatDiff.rows-10)){
                rowRangeHighS=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHighS=row+10;
            }
            
            cv::Mat selRegion;
            selRegion=movieFrameMatDiffOrig(cv::Range(rowRangeLowS,rowRangeHighS),cv::Range(colRangeLowS,colRangeHighS));
            cv::Mat wholeRegion;
            cv::Mat noSel=movieFrameMatDiffOrig.clone();
            //noSel(cv::Range(rowRangeLowS,rowRangeHighS),cv::Range(colRangeLowS,colRangeHighS))=cv::Scalar::all(0);
            wholeRegion=noSel(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh));
            
            cv::Scalar selAve=cv::mean(selRegion);
            cv::Scalar wholeAve=cv::mean(wholeRegion);
            
            movieFrameMatDiff(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(0);
            
            NSLog(@"center intensity norm: %f",selAve.val[0]/wholeAve.val[0]);
            
            if (selAve.val[0]>wholeAve.val[0]*1.2){
                
                /*cv::Mat selRegion8;
                 selRegion.convertTo(selRegion8, CV_8UC1);
                 UIImage * outUIImage = [[UIImage alloc] initWithCVMat:selRegion8];
                 UIImageWriteToSavedPhotosAlbum(outUIImage,
                 self, // send the message to 'self' when calling the callback
                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 NULL); // you generally won't need a contextInfo here
                 
                 cv::Mat wholeRegion8;
                 wholeRegion.convertTo(wholeRegion8, CV_8UC1);
                 UIImage * outUIImage2 = [[UIImage alloc] initWithCVMat:wholeRegion8];
                 //UIImageWriteToSavedPhotosAlbum(outUIImage2,
                 //                               self, // send the message to 'self' when calling the callback
                 //                               @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 //                               NULL); // you generally won't need a contextInfo here*/
                
                
                foundWorms(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(100);
                NSLog(@"%s","found some worms!");
                
                NSNumber *x = [NSNumber numberWithInt:maxIdx[1]];
                [coordsArray addObject:x];
                NSNumber *y = [NSNumber numberWithInt:maxIdx[0]];
                [coordsArray addObject:y];
                
                /*cv::Mat movieFrameMatDiff8;
                 movieFrameMatDiff.convertTo(movieFrameMatDiff8, CV_8UC1);
                 UIImage * outUIImage = [[UIImage alloc] initWithCVMat:movieFrameMatDiff8];
                 UIImageWriteToSavedPhotosAlbum(outUIImage,
                 self, // send the message to 'self' when calling the callback
                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 NULL); // you generally won't need a contextInfo here*/
            }
            
        }
        else {
            break;
            movieFrameMatDiff.release();
            movieFrameMatDiff=cv::Mat();
        }
    }
    // Now we are done finding worms
    
    
    movieFrameMatDiffOrig.convertTo(movieFrameMatDiffOrig,CV_16UC1);
    cv::Mat movieFrameMatDiffOrig8(480,270, CV_16UC1, cv::Scalar::all(0));
    double maxVal;
    int maxIdx;
    minMaxIdx(movieFrameMatDiffOrig, 0, &maxVal, 0, &maxIdx);
    cv::divide(movieFrameMatDiffOrig, 256*(maxVal/65535), movieFrameMatDiffOrig8);
    movieFrameMatDiffOrig8.convertTo(movieFrameMatDiffOrig8, CV_8UC1);
    std::vector<cv::Mat> planes;
    planes.push_back(movieFrameMatDiffOrig8+foundWorms);
    planes.push_back(movieFrameMatDiffOrig8);
    planes.push_back(movieFrameMatDiffOrig8);
    cv::Mat outImageRGB;
    cv::merge(planes,outImageRGB);
    planes.clear();
    //planes.swap(std::vector<cv::Mat> (planes));
    std::vector<cv::Mat> (planes).swap(planes);
    //cv::cvtColor(movieFrameMatDiffOrig8,outImageRGB, CV_GRAY2RGB);
    foundWorms.release();
    foundWorms=cv::Mat();
    movieFrameMatDiffOrig.release();
    movieFrameMatDiffOrig=cv::Mat();
    UIImage * outUIImage;
    outUIImage = [[UIImage alloc] initWithCVMat:outImageRGB];
    outImageRGB.release();
    outImageRGB=cv::Mat();
    UIImageWriteToSavedPhotosAlbum(outUIImage,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here*/
    
    
    /*UIImage * diffUIImage;
     diffUIImage = [[UIImage alloc] initWithCVMat:movieFrameMatDiffOrig8];
     UIImageWriteToSavedPhotosAlbum(diffUIImage,
     self, // send the message to 'self' when calling the callback
     @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
     NULL); // you generally won't need a contextInfo here*/
    
    
    movieFrameMatDiffOrig8.release();
    movieFrameMatDiffOrig8=cv::Mat();
    NSLog(@"%s","finished!");
    self.outImage=outUIImage;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"eventType"
     object:nil ];
}


-(void) analyzeImagesFast: (NSURL *)movieURL : (NSMutableArray *) movies {
    NSLog(@"starting analysis");
    //coordsArray=nil;
    coordsArray = [[NSMutableArray alloc] init];

    self.movieURL = movieURL;
    //[self setupGenerator];
    //first, average and convolve the images;
    int sz[3] = {360,480,3};
    cv::Mat outImage(3,sz, CV_16UC(1), cv::Scalar::all(0));
    cv::Mat kernel = cv::Mat::ones(4, 4, CV_32F);
    cv::Mat kernel2 = cv::Mat::ones(16, 16, CV_32F);
    cv::Mat kernel3 = cv::Mat::ones(67,67,CV_32F);
    cv::Mat movieFrameMatOld;
    cv::Mat movieFrameMatCum;
    cv::Mat movieFrameMatFirst;
    cv::Mat movieFrameMatDiff;
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat;
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNorm(360,480, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatNormOld;
    cv::Mat foundWorms(360,480, CV_8UC1, cv::Scalar::all(0));
    int i=1;
    int frame=1;
    int skip=2;
    int aveFrames=30/skip;
    while(i<115/skip) {
        while(i<=aveFrames) {
            //CGImage * test= movies[frame-1];
            CGImageRef test2=(__bridge CGImageRef)[movies objectAtIndex:(frame-1+15)];
            UIImage *test = [UIImage imageWithCGImage:test2];
            
            
            // Post notification about analysis progress
            // 80% of progress is loading videos
            // 3 total videos for now
            float newprogress = progress.doubleValue + (1/27.0)*(1/2.0);
            NSLog(@"newprogress: %f", newprogress);
            //if (newprogress > progress.doubleValue) {
            progress = [NSNumber numberWithDouble:newprogress];
            NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", nil];
            NSArray* objects = [[NSArray alloc] initWithObjects:progress, nil];
            NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
            //}
            
            NSLog(@"gen image: %i",frame);
            //movieFrameMat= [test cvMatCG];
            movieFrameMat= [test CVMat];
            
            test=nil;
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            cv::filter2D(movieFrameMat, movieFrameMat,-1,kernel,cv::Point(-1,-1));
            
            if (i==1){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                movieFrameMatCum=movieFrameMatOld+movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=cv::Mat();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            i=i+1;
            frame=frame+skip;
        }
        if (i==(aveFrames+1)){
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            //filter2D(movieFrameMatNorm, movieFrameMatNorm, -1 , kernel, cv::Point( -1, -1 ), 0, cv::BORDER_DEFAULT );
        }
        if (i>aveFrames+1) {
            //UIImage * test= movies[frame-1];
            CGImageRef cg2=(__bridge CGImageRef)[movies objectAtIndex:(frame-1+15)];
            UIImage *test = [UIImage imageWithCGImage:cg2];
            movieFrameMat= [test CVMat];
            
            
            test=nil;
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            cv::filter2D(movieFrameMat, movieFrameMat,-1,kernel,cv::Point(-1,-1));
            
            //UIImage * test2= movies[(frame-aveFrames+1)];
            CGImageRef cg3=(__bridge CGImageRef)[movies objectAtIndex:(frame-1+15)];
            UIImage *test2 = [UIImage imageWithCGImage:cg3];
            //UIImage * test2= [self generateImage:(frame-aveFrames+1)];
            
            
            movieFrameMatFirst= [test2 CVMat];
            test2=nil;
            cv::cvtColor(movieFrameMatFirst, movieFrameMatFirst, CV_RGB2GRAY);
            
            //comment if not using converted vids!!
            //cv::transpose(movieFrameMatFirst, movieFrameMatFirst);
            movieFrameMatFirst.convertTo(movieFrameMatFirst, CV_16UC1);
            cv::filter2D(movieFrameMatFirst, movieFrameMatFirst,-1,kernel,cv::Point(-1,-1));
            
            movieFrameMatCum=movieFrameMatCum-movieFrameMatFirst + movieFrameMat;
            movieFrameMat.release();
            movieFrameMat=cv::Mat();
            movieFrameMatFirst.release();
            movieFrameMatFirst=cv::Mat();
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            //cv::filter2D(movieFrameMatNorm, movieFrameMatNorm,-1,kernel,cv::Point(-1,-1));
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            movieFrameMatNormOld.release();
            movieFrameMatNormOld=cv::Mat();
            if (i==aveFrames+2){
                movieFrameMatDiff=movieFrameMatDiffTmp;
            }
            else {
                movieFrameMatDiff=movieFrameMatDiff+movieFrameMatDiffTmp;
            }
            movieFrameMatDiffTmp.release();
            movieFrameMatDiffTmp=cv::Mat();
        }
        movieFrameMatNormOld=movieFrameMatNorm.clone();
        movieFrameMatNorm.release();
        movieFrameMatNorm=cv::Mat();
        frame=frame+skip;
        i=i+1;
        
        // Post notification about analysis progress
        // 80% of progress is loading videos
        // 3 total videos for now
        float newprogress = progress.doubleValue + (1/33.0)*(1/2.0);
        NSLog(@"newprogress: %f", newprogress);
        //if (newprogress > progress.doubleValue) {
        progress = [NSNumber numberWithDouble:newprogress];
        NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", nil];
        NSArray* objects = [[NSArray alloc] initWithObjects:progress, nil];
        NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
        //}
        
        NSLog(@"Difference progress: %d", i);
    }
    cv::Mat movieFrameMatBack;
    
    //cv::Mat_<double>gk(49,49);
    //gk=cv::getGaussianKernel(2500,10,CV_32F);
    //cv::filter2D(movieFrameMatDiff, movieFrameMatBack,-1,gk,cv::Point(-1,-1));
    cv::Size ksize(49,49);
    //cv::GaussianBlur(movieFrameMatDiff,movieFrameMatBack, ksize, .5, 0, cv::BORDER_DEFAULT);
    
    //movieFrameMatDiff=movieFrameMatDiff-movieFrameMatBack;
    
    movieFrameMatDiffOrig = movieFrameMatDiff.clone();
    cv::Scalar imageAve = cv::mean(movieFrameMatDiffOrig);
    NSLog(@"img avg: %f",imageAve.val[0]);
    
    bool findinWorms=TRUE;
    while(findinWorms==TRUE) {
        cv::Mat findinWormsConv;
        cv::filter2D(movieFrameMatDiff, findinWormsConv,-1,kernel2,cv::Point(-1,-1));
        double maxVal;
        int maxIdx[2] = {255, 255};
        minMaxIdx(findinWormsConv, 0, &maxVal, 0, maxIdx);
        NSLog(@"img max: %f",maxVal);
        NSLog(@"max x: %i",maxIdx[0]);
        NSLog(@"max y: %i",maxIdx[1]);
        
        if (maxVal > (imageAve.val[0]*266)){
            
            int col=floor(maxIdx[1]);
            int row=maxIdx[0];
            int colRangeLow=0;
            int colRangeHigh=0;
            int rowRangeLow=0;
            int rowRangeHigh=0;
            if (col<25){
                colRangeLow=0;
            }
            else {
                colRangeLow=col-25;
            }
            if (col>(movieFrameMatDiff.cols-25)){
                colRangeHigh=movieFrameMatDiff.cols;
            }
            else {
                colRangeHigh=col+25;
            }
            
            if (row<25){
                rowRangeLow=0;
            }
            else {
                rowRangeLow=row-25;
            }
            if (row>(movieFrameMatDiff.rows-25)){
                rowRangeHigh=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHigh=row+25;
            }
            
            col=floor(maxIdx[1]);
            row=maxIdx[0];
            int colRangeLowS=0;
            int colRangeHighS=0;
            int rowRangeLowS=0;
            int rowRangeHighS=0;
            if (col<10){
                colRangeLowS=0;
            }
            else {
                colRangeLowS=col-10;
            }
            if (col>(movieFrameMatDiff.cols-10)){
                colRangeHighS=movieFrameMatDiff.cols;
            }
            else {
                colRangeHighS=col+10;
            }
            
            if (row<10){
                rowRangeLowS=0;
            }
            else {
                rowRangeLowS=row-10;
            }
            if (row>(movieFrameMatDiff.rows-10)){
                rowRangeHighS=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHighS=row+10;
            }
            
            cv::Mat selRegion;
            selRegion=movieFrameMatDiffOrig(cv::Range(rowRangeLowS,rowRangeHighS),cv::Range(colRangeLowS,colRangeHighS));
            cv::Mat wholeRegion;
            cv::Mat noSel=movieFrameMatDiffOrig.clone();
            //noSel(cv::Range(rowRangeLowS,rowRangeHighS),cv::Range(colRangeLowS,colRangeHighS))=cv::Scalar::all(0);
            wholeRegion=noSel(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh));
            
            cv::Scalar selAve=cv::mean(selRegion);
            cv::Scalar wholeAve=cv::mean(wholeRegion);
            
            movieFrameMatDiff(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(0);
            
            NSLog(@"center intensity norm: %f",selAve.val[0]/wholeAve.val[0]);
            
            if (selAve.val[0]>wholeAve.val[0]*1.2){
                
                /*cv::Mat selRegion8;
                 selRegion.convertTo(selRegion8, CV_8UC1);
                 UIImage * outUIImage = [[UIImage alloc] initWithCVMat:selRegion8];
                 UIImageWriteToSavedPhotosAlbum(outUIImage,
                 self, // send the message to 'self' when calling the callback
                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 NULL); // you generally won't need a contextInfo here
                 
                 cv::Mat wholeRegion8;
                 wholeRegion.convertTo(wholeRegion8, CV_8UC1);
                 UIImage * outUIImage2 = [[UIImage alloc] initWithCVMat:wholeRegion8];
                 //UIImageWriteToSavedPhotosAlbum(outUIImage2,
                 //                               self, // send the message to 'self' when calling the callback
                 //                               @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 //                               NULL); // you generally won't need a contextInfo here*/
                
                
                foundWorms(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(100);
                NSLog(@"%s","found some worms!");
                
                NSNumber *x = [NSNumber numberWithInt:maxIdx[1]];
                [coordsArray addObject:x];
                NSNumber *y = [NSNumber numberWithInt:maxIdx[0]];
                [coordsArray addObject:y];
                
                /*cv::Mat movieFrameMatDiff8;
                 movieFrameMatDiff.convertTo(movieFrameMatDiff8, CV_8UC1);
                 UIImage * outUIImage = [[UIImage alloc] initWithCVMat:movieFrameMatDiff8];
                 UIImageWriteToSavedPhotosAlbum(outUIImage,
                 self, // send the message to 'self' when calling the callback
                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                 NULL); // you generally won't need a contextInfo here*/
            }
            
        }
        else {
            break;
            movieFrameMatDiff.release();
            movieFrameMatDiff=cv::Mat();
        }
    }
    // Now we are done finding worms
    NSLog(@"done finding worms");
    
    
    movieFrameMatDiffOrig.convertTo(movieFrameMatDiffOrig,CV_16UC1);
    cv::Mat movieFrameMatDiffOrig8(360,480, CV_16UC1, cv::Scalar::all(0));
    double maxVal;
    int maxIdx;
    minMaxIdx(movieFrameMatDiffOrig, 0, &maxVal, 0, &maxIdx);
    cv::divide(movieFrameMatDiffOrig, 256*(maxVal/65535), movieFrameMatDiffOrig8);
    movieFrameMatDiffOrig8.convertTo(movieFrameMatDiffOrig8, CV_8UC1);
    std::vector<cv::Mat> planes;
    planes.push_back(movieFrameMatDiffOrig8+foundWorms);
    planes.push_back(movieFrameMatDiffOrig8);
    planes.push_back(movieFrameMatDiffOrig8);
    cv::Mat outImageRGB;
    cv::merge(planes,outImageRGB);
    planes.clear();
    //planes.swap(std::vector<cv::Mat> (planes));
    std::vector<cv::Mat> (planes).swap(planes);
    //cv::cvtColor(movieFrameMatDiffOrig8,outImageRGB, CV_GRAY2RGB);
    foundWorms.release();
    foundWorms=cv::Mat();
    movieFrameMatDiffOrig.release();
    movieFrameMatDiffOrig=cv::Mat();
    UIImage * outUIImage;
    outUIImage = [[UIImage alloc] initWithCVMat:outImageRGB];
    outImageRGB.release();
    outImageRGB=cv::Mat();
    UIImageWriteToSavedPhotosAlbum(outUIImage,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here*/
    
    
    /*UIImage * diffUIImage;
     diffUIImage = [[UIImage alloc] initWithCVMat:movieFrameMatDiffOrig8];
     UIImageWriteToSavedPhotosAlbum(diffUIImage,
     self, // send the message to 'self' when calling the callback
     @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
     NULL); // you generally won't need a contextInfo here*/
    
    
    movieFrameMatDiffOrig8.release();
    movieFrameMatDiffOrig8=cv::Mat();
    NSLog(@"%s","finished!");
    self.outImage=outUIImage;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"eventType"
     object:nil ];
}
- (UIImage *) getOutImage {
    return self.outImage;
}
- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"error saving image");
        
        // Do anything needed to handle the error or display it to the user
    } else {
        NSLog(@"image saved in photo album");
        
        // .... do anything you want here to handle
        // .... when the image has been saved in the photo album
    }
}
-(NSMutableArray *) getCoords{
    return coordsArray;
}
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    return cvMat;
}

- (int) getNumContours{
    return numContoursLast;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    // Unable to save the image
    if (error)
        NSLog(@"error saving image");
    else // All is well
        NSLog(@"image saved in photo album");
}
+ (cv::Mat)cvMatWithCGImage:(CGImageRef)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image);
    CGFloat rows = CGImageGetHeight(image);
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
    
    return cvMat;
}


@end