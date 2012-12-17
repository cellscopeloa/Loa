//
//  UITabBarController+InterfaceLock.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 12/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "UITabBarController+InterfaceLock.h"

@implementation UITabBarController (InterfaceLock)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
