//
//  SettingsDelegate.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 2/7/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SettingsDelegate <NSObject>

- (void)updateSensitivity:(float) value;

@end
