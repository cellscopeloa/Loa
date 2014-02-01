//
//  FirstRunViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 10/20/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "FirstRunViewController.h"

@interface FirstRunViewController ()

@end

@implementation FirstRunViewController

@synthesize deviceIDTextField;
@synthesize tabletModeButton;

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
	// Do any additional setup after loading the view.
    [tabletModeButton setOn:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDone:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:deviceIDTextField.text forKey:@"DeviceID"];
    [defaults setObject:[NSNumber numberWithBool:tabletModeButton.isOn] forKey:@"tabletMode"];
    [defaults setObject:@"notFirstRun" forKey:@"run"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
