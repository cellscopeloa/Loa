//
//  User.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * securityquestion;
@property (nonatomic, retain) NSString * securityanswer;
@property (nonatomic, retain) NSString * serialnumber;
@property (nonatomic, retain) NSManagedObject *settings;

@end
