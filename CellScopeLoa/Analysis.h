//
//  Analysis.h
//  CellScope
//
//  Created by Mike D'Ambrosio on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>



@interface Analysis : NSObject
{    
}
-(int)getNumContours;
-(UIImage *)generateImage:(int) frame;
-(UIImage *) getOutImage;
-(void)analyzeImagesNew:(NSURL*) movieURL;
@property NSURL * movieURL;
@property UIImage * outImage;


@end
