//
//  CountViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "SampleMovie.h"
#import "CountViewController.h"

#define NUMFOV 5.0

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
@synthesize serialLabel;
@synthesize statusBox;

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
    serialLabel.text = sample.serialnumber;
    float numberoffov = NUMFOV;
    NSSet* movies = sample.movies;
    double featureCount = 0;
    for (SampleMovie* sampleMovie in movies) {
        double coordinateWrites = 5.0;
        double averageFeatures = (double)(sampleMovie.features.count) / coordinateWrites;
        featureCount += averageFeatures;
    }
    
    double averageWorms = featureCount / numberoffov;
    int estimatedCount = (int)((featureCount / numberoffov) / (.00073));
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle]; // this line is important!
    
    NSString* astr = [formatter stringFromNumber:[NSNumber numberWithFloat:averageWorms]];
    NSString* bstr = [formatter stringFromNumber:[NSNumber numberWithFloat:estimatedCount]];
    
    if(estimatedCount > 30000) {
        statusBox.backgroundColor = [UIColor redColor];
    }
    else {
        statusBox.backgroundColor = [UIColor greenColor];
    }
    wormCountMl.text = [NSString stringWithFormat:@"%@ mf/ml", bstr];
    wormCountAbs.text = [NSString stringWithFormat:@"%@ mf/field", astr];
}

-(void)setupInstructionSet
{
    instructionText = [NSArray arrayWithObjects: @"Test results are displayed below, please consult treatment plan.", nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
