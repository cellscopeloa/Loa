//
//  MainMenuViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/10/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "SettingsDelegate.h"

@protocol SelectUserDelegate <NSObject>
@required
- (void)didSelectUser:(NSString *)username;
@end

@interface MainMenuViewController : UITableViewController <SettingsDelegate, SelectUserDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, assign) float sensitivity;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@end