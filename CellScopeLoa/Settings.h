//
//  Settings.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Settings : NSManagedObject

@property (nonatomic, retain) NSString * guided;
@property (nonatomic, retain) User *user;

@end
