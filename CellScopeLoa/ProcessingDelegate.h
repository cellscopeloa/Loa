//
//  ProcessingDelegate.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 2/6/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ProcessingDelegate <NSObject>

- (void)processedMovieResult:(UIImage*)image;

@end
