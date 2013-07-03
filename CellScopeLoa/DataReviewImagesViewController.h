//
//  DataReviewImagesViewController.h
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sample.h"

@interface DataReviewImagesViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) Sample* sample;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

- (void)loadNextPhoto;

@end