//
//  InstructionViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/28/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "InstructionViewController.h"

@interface InstructionViewController ()

@end

@implementation InstructionViewController

@synthesize touchIcon;
@synthesize instructImage;
@synthesize instructLabel;
@synthesize instructSet;
@synthesize currentInstruct;
@synthesize instructIdx;

-(void)setupInstructionSet
{
    instructSet = [NSMutableDictionary dictionary];
    
    NSArray *setupImages = [NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"patient_step_a_1"],
                                    [UIImage imageNamed:@"patient_step_b_2"],
                                    [UIImage imageNamed:@"sample_step_a_3"],
                                    [UIImage imageNamed:@"sample_step_c_5"],
                                    [UIImage imageNamed:@"position_step_a_6"],
                                    [UIImage imageNamed:@"focus_step_a_7"], nil];
    NSArray *setupLabels = [NSArray arrayWithObjects:
                            NSLocalizedString(@"PATIENTSTEPA",nil),
                            NSLocalizedString(@"PATIENTSTEPB", nil),
                            NSLocalizedString(@"SAMPLESTEPA",nil),
                            NSLocalizedString(@"SAMPLESTEPC",nil),
                            NSLocalizedString(@"POSITIONSTEPA", nil),
                            NSLocalizedString(@"FOCUSSTEPA",nil),nil];
    NSDictionary *setup = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: setupImages, setupLabels, nil] forKeys: [NSArray arrayWithObjects: @"images", @"labels", nil]];
    [instructSet setObject:setup forKey:@"setup"];
}

-(void)setupAnimations
{
    NSMutableArray *touchImages = [[NSMutableArray alloc] init];
    for (int i = 1; i < 10; i++) {
        [touchImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"touch%01d.png",i]]];
    }
    for (int j = 9; j > 0; j--) {
        [touchImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"touch%01d.png",j]]];
    }
    
    touchIcon.animationImages = touchImages;
    // all frames will execute in 1.75 seconds
    touchIcon.animationDuration = 1.75;
    // repeat the annimation forever
    touchIcon.animationRepeatCount = 0;
    // start animating
    [touchIcon startAnimating];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if(segue.identifier == @"captureImage") {
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    currentInstruct = @"setup";
    instructIdx = 0;
    
    [self setupInstructionSet];
    [self setupAnimations];
    
    NSDictionary *instructions = [instructSet objectForKey:currentInstruct];
    NSArray* images = [instructions objectForKey:@"images"];
    NSArray* labels = [instructions objectForKey:@"labels"];
    
    instructImage.image = [images objectAtIndex:instructIdx];
    instructLabel.text = [labels objectAtIndex:instructIdx];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTap:(id)sender {
    
    NSDictionary *instructions = [instructSet objectForKey:currentInstruct];
    NSArray* images = [instructions objectForKey:@"images"];
    NSArray* labels = [instructions objectForKey:@"labels"];
        
    instructIdx += 1;
    if(instructIdx == images.count) {
        [self performSegueWithIdentifier:@"captureImage" sender:self];
    }
    else {
        [UIView animateWithDuration:0.1 animations:^{
            instructImage.alpha = 0.0;
            instructLabel.alpha = 0.0;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.5 animations:^{
                if(instructIdx == images.count) {
                    instructIdx -= 1;
                    [self performSegueWithIdentifier:@"captureImage" sender:self];
                }
                instructImage.image = [images objectAtIndex:instructIdx];
                instructImage.alpha = 1.0;
                instructLabel.alpha = 1.0;
                instructLabel.text = [labels objectAtIndex:instructIdx];
            } completion:^(BOOL finished){ }];
        }];
    }
}

@end
