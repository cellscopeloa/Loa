//
//  Settings.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 2/7/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Settings : NSManagedObject

@property (nonatomic, retain) NSString * guided;
@property (nonatomic, retain) NSNumber * sensitivity;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) User *user;

@end
