//
//  LoaProgram.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoaProgram : NSObject

@property (weak, nonatomic) NSString* guided;
@property (nonatomic) NSInteger fovnumber;

-(LoaProgram*)initWithMode:(NSString*)guided;

@end