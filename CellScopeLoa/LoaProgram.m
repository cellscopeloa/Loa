//
//  LoaProgram.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "LoaProgram.h"

@implementation LoaProgram

@synthesize guided;

-(LoaProgram*)initWithMode:(NSString *)guidedMode
{
    self = [super init];
    self.guided = guidedMode;
    return self;
}

@end
