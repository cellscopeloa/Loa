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

-(id)init
{
    self=[super init];
    return self;
}
-(UIImage *)generateImage:(int) frame
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:self.movieURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    //reverse for non-converted video (270,480)
    CGSize maxSize = CGSizeMake(480, 270);
    generator.maximumSize = maxSize;
    generator.requestedTimeToleranceBefore=kCMTimeZero;
    generator.requestedTimeToleranceAfter=kCMTimeZero;
    
    //NSLog(@"%i", frame);
    
    CMTime thumbTime = CMTimeMake(frame,30);
    //NSLog(@"%lld", thumbTime.value);
    NSError *err = NULL;
    CGImage * im=[generator copyCGImageAtTime:thumbTime actualTime:NULL error:&err];
    UIImage * retImg=[UIImage imageWithCGImage:im];
    CGImageRelease(im);
    return retImg;
    
}

-(void) analyzeImagesNew: (NSURL *) movieURL{
    self.movieURL=movieURL;
    //first, average and convolve the images;
    int sz[3] = {480,270,3};
    cv::Mat outImage(3,sz, CV_16UC(1), cv::Scalar::all(0));
    cv::Mat kernel = cv::Mat::ones(3, 3, CV_32F);
    cv::Mat kernel2 = cv::Mat::ones(50, 50, CV_32F);
    cv::Mat movieFrameMatOld;
    cv::Mat movieFrameMatCum;
    cv::Mat movieFrameMatFirst(480,270, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatDiff;
    cv::Mat movieFrameMatDiffTmp;
    cv::Mat movieFrameMat(480,270, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatDiffOrig;
    cv::Mat movieFrameMatNorm(480,270, CV_16UC1, cv::Scalar::all(0));
    cv::Mat movieFrameMatNormOld(480,270, CV_16UC1, cv::Scalar::all(0));
    cv::Mat foundWorms(480,270, CV_8UC1, cv::Scalar::all(0));
    int i=1;
    int aveFrames=30;
    while (i<120){
        while (i<=aveFrames){
            UIImage * test= [self generateImage:(i-1)];
            movieFrameMat= [test CVMat];
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            //comment if not using converted vids!!
            cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            if (i==1){
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
            }
            else {
                movieFrameMatCum=movieFrameMatOld+movieFrameMat;
                movieFrameMatOld.release();
                movieFrameMatOld=movieFrameMat;
                movieFrameMat.release();
            }
            NSLog(@"%i",i);
            i=i+1;
        }
        
        if (i==(aveFrames+1)){
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            filter2D(movieFrameMatNorm, movieFrameMatNorm, -1 , kernel, cv::Point( -1, -1 ), 0, cv::BORDER_DEFAULT );
        }
        if (i>aveFrames+1) {
            UIImage * test= [self generateImage:(i-1)];
            movieFrameMat= [test CVMat];
            cv::cvtColor(movieFrameMat, movieFrameMat, CV_RGB2GRAY);
            //comment if not using converted vids!!
            cv::transpose(movieFrameMat, movieFrameMat);
            movieFrameMat.convertTo(movieFrameMat, CV_16UC1);
            UIImage * test2= [self generateImage:(i-aveFrames+1)];
            movieFrameMatFirst= [test2 CVMat];
            cv::cvtColor(movieFrameMatFirst, movieFrameMatFirst, CV_RGB2GRAY);
            //comment if not using converted vids!!
            cv::transpose(movieFrameMatFirst, movieFrameMatFirst);
            movieFrameMatFirst.convertTo(movieFrameMatFirst, CV_16UC1);
            movieFrameMatCum=movieFrameMatCum-movieFrameMatFirst + movieFrameMat;
            movieFrameMat.release();
            movieFrameMatFirst.release();
            cv::divide(movieFrameMatCum, aveFrames, movieFrameMatNorm);
            cv::filter2D(movieFrameMatNorm, movieFrameMatNorm,-1,kernel,cv::Point(-1,-1));
            cv::absdiff(movieFrameMatNormOld, movieFrameMatNorm, movieFrameMatDiffTmp);
            movieFrameMatOld.release();
            if (i==aveFrames+2){
                movieFrameMatDiff=movieFrameMatDiffTmp;
                movieFrameMatDiffTmp.release();
            }
            else {
                movieFrameMatDiff=movieFrameMatDiff+movieFrameMatDiffTmp;
                movieFrameMatDiffTmp.release();
            }
        }
        movieFrameMatNormOld=movieFrameMatNorm;
        movieFrameMatNorm.release();
        NSLog(@"%i",i);
        movieFrameMat=cv::Mat();
        movieFrameMatFirst=cv::Mat();
        movieFrameMatNorm=cv::Mat();
        movieFrameMatDiffTmp=cv::Mat();
        i=i+1;
    }
    movieFrameMatDiffOrig=movieFrameMatDiff.clone();
    bool findinWorms=TRUE;
    while (findinWorms==TRUE){
        cv::Mat findinWormsConv;
        cv::filter2D(movieFrameMatDiff, findinWormsConv,-1,kernel,cv::Point(-1,-1));
        double maxVal;
        int maxIdx[2] = {255, 255};
        minMaxIdx(findinWormsConv, 0, &maxVal, 0, maxIdx);
        NSLog(@"%f",maxVal);
        NSLog(@"%i",maxIdx[0]);
        NSLog(@"%i",maxIdx[1]);
        if (maxVal>650){
            int col=floor(maxIdx[1]);
            int row=maxIdx[0];
            int colRangeLow=0;
            int colRangeHigh=0;
            int rowRangeLow=0;
            int rowRangeHigh=0;
            if (col<25){
                colRangeLow=1;
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
                rowRangeLow=1;
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
            movieFrameMatDiff(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(0);
            foundWorms(cv::Range(rowRangeLow,rowRangeHigh),cv::Range(colRangeLow,colRangeHigh))=cv::Scalar::all(100);
            NSLog(@"%s","found some worms!");
        }
        else {
            break;
        }
    }
    movieFrameMatDiffOrig.convertTo(movieFrameMatDiffOrig,CV_16UC1);
    movieFrameMatDiffOrig+foundWorms;
    std::vector<cv::Mat> planes;
    cv::Mat movieFrameMatDiffOrig8(480,270, CV_16UC1, cv::Scalar::all(0));
    double maxVal;
    int maxIdx;
    minMaxIdx(movieFrameMatDiffOrig, 0, &maxVal, 0, &maxIdx);
    cv::divide(movieFrameMatDiffOrig, 256*(maxVal/65535), movieFrameMatDiffOrig8);
    movieFrameMatDiffOrig8.convertTo(movieFrameMatDiffOrig8, CV_8UC1);
    planes.push_back(movieFrameMatDiffOrig8+foundWorms);
    planes.push_back(movieFrameMatDiffOrig8);
    planes.push_back(movieFrameMatDiffOrig8);
    cv::Mat outImageRGB;
    cv::merge(planes,outImageRGB);
    UIImage * outUIImage;
    outUIImage = [[UIImage alloc] initWithCVMat:outImageRGB];
    UIImageWriteToSavedPhotosAlbum(outUIImage,
                                   self, // send the message to 'self' when calling the callback
                                   @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                   NULL); // you generally won't need a contextInfo here
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
        // Do anything needed to handle the error or display it to the user
    } else {
        // .... do anything you want here to handle
        // .... when the image has been saved in the photo album
    }
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

@end