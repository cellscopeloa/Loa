//
//  MotionAnalysis.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 1/26/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "MotionAnalysis.h"
#import "UIImage+OpenCV.h"
#import "LoaProgram.h"


@implementation MotionAnalysis {
    NSMutableArray* movieLengths;
    std::vector<cv::Mat> *frameBuffers;
    NSInteger movieIdx;
    NSInteger frameIdx;
    NSInteger numFramesMax;
    NSInteger numMovies;
    double progress;
}

@synthesize coordsArray;
@synthesize outImage;
@synthesize urls;
@synthesize coordinatesPerMovie;
@synthesize delegate;

-(id)initWithWidth:(NSInteger)width Height:(NSInteger)height Frames:(NSInteger)frames Movies:(NSInteger)movies {
    //test git
    self = [super init];
    
    progress = 0.0;
    
    movieIdx = 0;
    frameIdx = 0;
    numFramesMax = frames;
    numMovies = movies;
    
    coordsArray = [[NSMutableArray alloc] init];
    movieLengths = [[NSMutableArray alloc] init];
    urls = [[NSMutableArray alloc] init];
    coordinatesPerMovie = [[NSMutableArray alloc] init];


    
    frameBuffers = new std::vector<cv::Mat>(frames*movies);
    
    for(int i=0; i<frames*movies; i++) {
        cv::Mat buffer(height,width,CV_8UC1);
        frameBuffers->at(i) = buffer;
    }
    
    return self;
}

-(void)writeNextFrame:(CVBufferRef)imageBuffer
{    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    // Get information about the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a CGImageRef from the CVImageBufferRef
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // This copies the data, may be eliminated to optimize code later on
    CGImageRef image = CGBitmapContextCreateImage(newContext);
    // Cleanup the CG creators
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    // Unlock the  image buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = width;
    CGFloat rows = height;
    
    // Create an RGBA frame for converting the CGImage
    
    // Grab the current movie from the frame buffer list
    int bufferIdx = movieIdx*numFramesMax + frameIdx;
    cv::Mat grayBuffer = frameBuffers->at(bufferIdx);
    
    // Create a grayscale opencv image from the RGBA buffer
    cv::Mat colorimage(rows,cols,CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(colorimage.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    colorimage.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    // Release the CGImage memory. This is a place for optimization
    CGImageRelease(image);
    
    // Copy the color image into the grayscale buffer
    cv::cvtColor(colorimage, grayBuffer, CV_BGRA2GRAY);
    
    // Advance the frame counter
    frameIdx++;
}

// Advance the write buffer to the next movie
- (void)nextMovie:(NSURL*) url {
    NSLog(@"%d frames in last movie", frameIdx-1);
    NSNumber* movlen = [NSNumber numberWithInt:(frameIdx-1)];
    [movieLengths addObject:movlen];
    [urls addObject:url];
    movieIdx++;
    frameIdx = 0;
}

-(void)processAllMovies {
    for(int i=0; i<numMovies; i++) {
        [self processFramesForMovie:i];
    }
    // Notify that processing is complete
    
    // Release all of the image buffers
    for(int i=0; i<numMovies*numFramesMax; i++) {
        frameBuffers->at(i).release();
    }
    
    NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", @"done", @"coords",@"urls", nil];
    NSArray* objects = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:1.0],[NSNumber numberWithInt:1],coordinatesPerMovie,urls,nil];
    NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
}

- (void)processFramesForMovie:(NSInteger)movidx {
    // Start at the first frame
    frameIdx = 0;
    coordsArray = [[NSMutableArray alloc] init];

    movieIdx = movidx;
    NSNumber *movielength = [movieLengths objectAtIndex:0];
    NSInteger numFrames = [movielength integerValue];
    
    // Movie dimensions
    int totalframes = numFrames;
    int rows = 360;
    int cols = 480;
    int wormSize=66; //must be even
    int innerBoxSize=26; //must be even
    int sz[3] = {rows,cols,3};
    
    
    // Algorithm parameters
    int framesToAvg = 30;
    int framesToSkip = 2; //WARNING- verify bufferIdx after changing, might not scale right
    
    // Image for storing the output...
    cv::Mat outImage(3, sz, CV_16UC(1), cv::Scalar::all(0));
    
    // Kernels for block averages
    cv::Mat blockAvg3x3 = cv::Mat::ones(4, 4, CV_32F);
    cv::Mat blockAvg12x12 = cv::Mat::ones(16, 16, CV_32F);
    cv::Mat blockAvg50x50 = cv::Mat::ones(67,67,CV_32F);
    
    // Matrix for storing normalized frames
    cv::Mat movieFrameMatNorm(rows, cols, CV_16UC1);
    // Matrix for storing found blocks of motion
    cv::Mat foundWorms(rows, cols, CV_8UC1, cv::Scalar::all(0));
    // Temporary matrices for image processing
    cv::Mat movieFrameMatOld;
    //cv::Mat movieFrameMatCum;
    cv::Mat movieFrameMatCum(rows,cols, CV_16UC1, cv::Scalar::all(0));

    cv::Mat movieFrameMatFirst;
    cv::Mat movieFrameMatDiff;
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat;
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNormOld;
    
    int i = 0;
    int avgFrames = framesToAvg/framesToSkip;
    frameIdx = 0;
    
    // Compute difference image from current movie
    
    //while(i < 50/framesToSkip) {
    //while(i < numFrames/framesToSkip) {
    while(frameIdx+avgFrames <= numFrames) {

        [self setProgressWithMovie:movidx Frame:frameIdx];
        while(i <= avgFrames) {
            //NSLog(@"numFrames: %i", numFrames);
            //NSLog(@"i: %i", i);

            // Update the progress bar
            [self setProgressWithMovie:movidx Frame:frameIdx];
            
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx+avgFrames);
            //NSLog(@"bufferidxinit: %i", bufferIdx);
            movieFrameMat = frameBuffers->at(bufferIdx);
            
            /******debug*/
            /*if (i%10==0){
                NSLog(@"writing debug image");
                cv::Mat debugOut(rows, cols, CV_8UC1, cv::Scalar::all(0));
                movieFrameMat.convertTo(debugOut, CV_8UC1);
                UIImage * outUIImage = [[UIImage alloc] initWithCVMat:debugOut];
                UIImageWriteToSavedPhotosAlbum(outUIImage,
                                               self, // send the message to 'self' when calling the callback
                                               @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                               NULL); // you generally won't need a contextInfo here
            }*/
            
            // Convert the frame into 16 bit grayscale. Space for optimization
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            
            // 3x3 spatial filter to reduce noise and downsample
            cv::filter2D(movieFrameMat, movieFrameMat, -1, blockAvg3x3, cv::Point(-1,-1));
            
            if (i == 0){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            else {
                movieFrameMatCum = movieFrameMatCum + movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=cv::Mat();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
                movieFrameMat=cv::Mat();
            }
            i=i+1;
            frameIdx = frameIdx + framesToSkip;
        }
        //NSLog(@"i: %i", i);

        if (i == avgFrames+1){
            //NSLog(@"dividing first cum image");
            cv::divide(movieFrameMatCum, avgFrames, movieFrameMatNorm);
            //filter2D(movieFrameMatNorm, movieFrameMatNorm, -1 , kernel, cv::Point( -1, -1 ), 0, cv::BORDER_DEFAULT );
        }
        if (i > avgFrames+1) {
            // Grab the current movie from the frame buffer list
            int bufferIdx = movieIdx*numFramesMax + (frameIdx+avgFrames-framesToSkip);
            //NSLog(@"bufferidxadd: %i", bufferIdx);
            movieFrameMat = frameBuffers->at(bufferIdx);
            
            // Convert the frame into 16 bit grayscale. Space for optimization
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            // 3x3 spatial filter to reduce noise and downsample
            cv::filter2D(movieFrameMat, movieFrameMat, -1, blockAvg3x3, cv::Point(-1,-1));
            
            // Grab the first frame from the current ave from the frame buffer list
            bufferIdx = movieIdx*numFramesMax + (frameIdx-avgFrames-framesToSkip-framesToSkip);
            //NSLog(@"bufferidxfirst: %i", bufferIdx);

            movieFrameMatFirst = frameBuffers->at(bufferIdx);
            
            // Convert the frame into 16 bit grayscale. Space for optimization
            movieFrameMatFirst.convertTo(movieFrameMatFirst, CV_16UC1);
            
            // 3x3 spatial filter to reduce noise and downsample
            cv::filter2D(movieFrameMatFirst, movieFrameMatFirst, -1, blockAvg3x3, cv::Point(-1,-1));
            
            movieFrameMatCum = movieFrameMatCum - movieFrameMatFirst + movieFrameMat;
            movieFrameMat.release();
            movieFrameMat=cv::Mat();
            movieFrameMatFirst.release();
            movieFrameMatFirst=cv::Mat();
            cv::divide(movieFrameMatCum, avgFrames, movieFrameMatNorm);
            //cv::filter2D(movieFrameMatNorm, movieFrameMatNorm,-1,kernel,cv::Point(-1,-1));
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            
            movieFrameMatNormOld.release();
            movieFrameMatNormOld=cv::Mat();
            if (i == avgFrames+2) {
                movieFrameMatDiff=movieFrameMatDiffTmp;
            }
            else {
                movieFrameMatDiff = movieFrameMatDiff + movieFrameMatDiffTmp;
                

            }
            movieFrameMatDiffTmp.release();
            movieFrameMatDiffTmp=cv::Mat();
        }
        movieFrameMatNormOld=movieFrameMatNorm.clone();
        movieFrameMatNorm.release();
        movieFrameMatNorm=cv::Mat();
        frameIdx = frameIdx + framesToSkip;
        i = i+1;
    }
    
    cv::Mat movieFrameMatBack;
    //cv::Mat_<double>gk(49,49);
    //gk=cv::getGaussianKernel(2500,10,CV_32F);
    //cv::filter2D(movieFrameMatDiff, movieFrameMatBack,-1,gk,cv::Point(-1,-1));
    //cv::Size ksize(49,49);
    //cv::GaussianBlur(movieFrameMatDiff,movieFrameMatBack, ksize, .5, 0, cv::BORDER_DEFAULT);
    //movieFrameMatDiff=movieFrameMatDiff-movieFrameMatBack;
    
    movieFrameMatDiffOrig = movieFrameMatDiff.clone();
    cv::Scalar imageAve = cv::mean(movieFrameMatDiffOrig);
    NSLog(@"img avg: %f",imageAve.val[0]);
    
    bool findinWorms=TRUE;
    while(findinWorms==TRUE) {
        cv::Mat findinWormsConv;
        cv::filter2D(movieFrameMatDiff, findinWormsConv,-1,blockAvg12x12,cv::Point(-1,-1));
        double maxVal;
        int maxIdx[2] = {255, 255};
        minMaxIdx(findinWormsConv, 0, &maxVal, 0, maxIdx);
        NSLog(@"img max: %f",maxVal);
        NSLog(@"max x: %i",maxIdx[0]);
        NSLog(@"max y: %i",maxIdx[1]);
        //only advance to the next stage of worm id if the patch max is 266 times higher than the image ave
        if (maxVal > (imageAve.val[0]*266)){
            //setup our box sizes around the worm
            int col=floor(maxIdx[1]);
            int row=maxIdx[0];
            int colRangeLow=0;
            int colRangeHigh=0;
            int rowRangeLow=0;
            int rowRangeHigh=0;
            if (col<(wormSize/2)){
                colRangeLow=0;
            }
            else {
                colRangeLow=col-(wormSize/2);
            }
            if (col>(movieFrameMatDiff.cols-(wormSize/2))){
                colRangeHigh=movieFrameMatDiff.cols;
            }
            else {
                colRangeHigh=col+(wormSize/2);
            }
            
            if (row<(wormSize/2)){
                rowRangeLow=0;
            }
            else {
                rowRangeLow=row-(wormSize/2);
            }
            if (row>(movieFrameMatDiff.rows-(wormSize/2))){
                rowRangeHigh=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHigh=row+(wormSize/2);
            }
            
            col=floor(maxIdx[1]);
            row=maxIdx[0];
            int colRangeLowS=0;
            int colRangeHighS=0;
            int rowRangeLowS=0;
            int rowRangeHighS=0;
            if (col<(innerBoxSize/2)){
                colRangeLowS=0;
            }
            else {
                colRangeLowS=col-(innerBoxSize/2);
            }
            if (col>(movieFrameMatDiff.cols-(innerBoxSize/2))){
                colRangeHighS=movieFrameMatDiff.cols;
            }
            else {
                colRangeHighS=col+(innerBoxSize/2);
            }
            
            if (row<(innerBoxSize/2)){
                rowRangeLowS=0;
            }
            else {
                rowRangeLowS=row-(innerBoxSize/2);
            }
            if (row>(movieFrameMatDiff.rows-(innerBoxSize/2))){
                rowRangeHighS=movieFrameMatDiff.rows;
            }
            else {
                rowRangeHighS=row+(innerBoxSize/2);
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
                foundWorms(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(100);
                NSLog(@"%s","found some worms!");
                
                NSNumber *x = [NSNumber numberWithInt:maxIdx[1]];
                [coordsArray addObject:x];
                NSNumber *y = [NSNumber numberWithInt:maxIdx[0]];
                [coordsArray addObject:y];
                }
            
        }
        else {
            break;
            movieFrameMatDiff.release();
            movieFrameMatDiff=cv::Mat();
        }
    }

    [coordsArray addObject:urls[movidx]];

    [coordinatesPerMovie addObject:coordsArray];
    // Now we are done finding worms
    NSLog(@"done finding worms");
    
    
    movieFrameMatDiffOrig.convertTo(movieFrameMatDiffOrig,CV_16UC1);
    cv::Mat movieFrameMatDiffOrig8(rows,cols, CV_16UC1, cv::Scalar::all(0));
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
    
    movieFrameMatDiffOrig8.release();
    movieFrameMatDiffOrig8=cv::Mat();
    NSLog(@"%s","finished!");
    self.outImage=outUIImage;
}

- (void)setProgressWithMovie:(NSInteger)midx Frame:(NSInteger)fidx
{
    double movieProgress = midx/(double)numMovies;
    NSInteger nframes = [[movieLengths objectAtIndex:movieIdx] integerValue];
    double frameProgress = (fidx/(double)nframes) * (1/(double)numMovies);
    double totalprogress = movieProgress+frameProgress;
    NSArray* keys = [[NSArray alloc] initWithObjects:@"progress", @"done", nil];
    NSArray* objects = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:totalprogress],
                                                        [NSNumber numberWithInt:0],
                                                        nil];
    NSDictionary* userInfo = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisProgress" object:self userInfo:userInfo];
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    if (error) {
        NSLog(@"error saving image");
        
        // Do anything needed to handle the error or display it to the user
    } else {
        NSLog(@"image saved in photo album");
        [delegate processedMovieResult:image];
        
        // .... do anything you want here to handle
        // .... when the image has been saved in the photo album
    }
}

@end
