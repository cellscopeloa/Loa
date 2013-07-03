//
//  DataTableViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataTableViewController : UITableViewController

@property (nonatomic, strong) NSNumber* lastSelectedIndex;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSArray* samples;
- (IBAction)donePressed:(id)sender;

@end
