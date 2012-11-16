//
//  MovieProgressDelegate.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/4/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MovieProgressDelegate <NSObject>

- (void)progressUpdate:(Float32)progress;
- (void)progressTaskComplete;

@end
