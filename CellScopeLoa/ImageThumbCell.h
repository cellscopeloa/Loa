//
//  ImageThumbCell.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageThumbCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *syncIcon;

@end
