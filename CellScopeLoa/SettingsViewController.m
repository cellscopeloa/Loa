//
//  SettingsViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 2/7/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "SettingsViewController.h"
#import "MainMenuViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize managedObjectContext;
@synthesize sensitivityIndicator;
@synthesize delegate;
@synthesize sensitivitySlide;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* sense = [defaults objectForKey:@"sensitivity"];
    sensitivitySlide.value = (sense.floatValue + 1.0)/2.0;
    sensitivityIndicator.text = [NSString stringWithFormat:@"%.2f", sense.floatValue];
    NSLog(@"Loaded sensitivity: %f", sense.floatValue);


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"MainMenu"]) {
        
        NSLog(@"Setting sensitivty in the defaults");
        
        MainMenuViewController* menu = [segue destinationViewController];
        float sense = sensitivitySlide.value * 2.0 - 1.0;
        [menu updateSensitivity:sense];
        
        // Store sensitivity
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithFloat:sense] forKey:@"sensitivity"];
        [defaults synchronize];
        
        menu.managedObjectContext = managedObjectContext;
    }
}

#pragma mark - Table view data source

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        float sense = 0.0;
        sensitivitySlide.value = (sense + 1.0)/2.0;
        sensitivityIndicator.text = [NSString stringWithFormat:@"%.2f", sense];
        
        // Store sensitivity
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSNumber numberWithFloat:sense] forKey:@"sensitivity"];
        [defaults synchronize];

    }
    // Navigation logic may go here. Create and push another view controller.
}

- (IBAction)sensitivityValueChanged:(id)sender {
    float sense = sensitivitySlide.value * 2.0 - 1.0;
    if (fabs(sense) < 0.05) {
        sense = 0.0;
        sensitivitySlide.value = 0.5;
    }
    sensitivityIndicator.text = [NSString stringWithFormat:@"%.2f", sense];
}
@end
