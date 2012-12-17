//
//  Analysis.h
//  CellScope
//
//  Created by Mike D'Ambrosio on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>



@interface Analysis : NSObject
{
    NSMutableArray *array;

}
-(int)getNumContours;
-(UIImage *)generateImage:(int) frame;
-(UIImage *) getOutImage;
-(void)analyzeImagesNew:(NSURL*) movieURL;
-(void)addURL:(NSURL*) movieURL;
-(void)startAnalysis;
-(NSMutableArray *) getCoords;

@property NSURL * movieURL;
@property UIImage * outImage;
@property AVURLAsset *asset;
@property AVAssetImageGenerator *generator;
@property NSMutableArray *coordsArray;
@property NSNumber *progress;

@end
