//
//  CountViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "SampleMovie.h"
#import "CountViewController.h"

@interface CountViewController () {
    NSArray* sampleMovies;
    NSArray* instructionText;
}

@end

@implementation CountViewController

@synthesize sample;
@synthesize colorBox;
@synthesize wormCountAbs;
@synthesize wormCountMl;
@synthesize InstructionTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupInstructionSet];
    InstructionTextView.text = [instructionText objectAtIndex:0];
	// Do any additional setup after loading the view.
    sampleMovies = [[sample movies] allObjects];
    float numberoffov = 3.0;
    int wormcount = 0;
    for (SampleMovie* sm in sampleMovies) {
        wormcount += [[sm features] count];
    }
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!
    
    float avg_worms = wormcount/numberoffov;
    int estimated_count = ((wormcount / numberoffov) / (.00073));
    NSString* astr = [formatter stringFromNumber:[NSNumber numberWithFloat:avg_worms]];
    NSString* bstr = [formatter stringFromNumber:[NSNumber numberWithFloat:estimated_count]];
    
    NSString* mffov = [[NSString alloc] initWithFormat:@"%@ mf/fov", astr];
    NSString* mfml = [[NSString alloc] initWithFormat:@"%@ mf/ml", bstr];
    wormCountAbs.text = mffov;
    wormCountMl.text = mfml;
    if(estimated_count > 30000) {
        colorBox.backgroundColor = [UIColor redColor];
    }
    else {
        colorBox.backgroundColor = [UIColor greenColor];
    }
}

-(void)setupInstructionSet
{
    instructionText = [NSArray arrayWithObjects: @"Test results are displayed below, please consult treatment plan. Press done button to continue.", nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
