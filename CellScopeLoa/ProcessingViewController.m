//
//  ProcessingViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/16/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ProcessingViewController.h"
#import "Sample.h"
#import "SampleMovie.h"
#import "ReviewViewController.h"

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController

@synthesize instructions;
@synthesize program;

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
    instructions.text = NSLocalizedString(@"PROCESSING",nil);
	// Do any additional setup after loading the view
    [self processImages];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Analyze"]) {
        ReviewViewController* reviewViewController = segue.destinationViewController;
        reviewViewController.program = program;
    }
}

- (void)processImages
{
    NSManagedObjectContext* managedObjectContext = program.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample" inManagedObjectContext: managedObjectContext];
    [request setEntity:entity];
    NSString* serial = program.currentSampleSerial;
    NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"serialnumber LIKE %@", serial];
    [request setPredicate:searchFilter];
    NSError* error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    if(results.count == 0) {
        NSLog(@"Couldn't fetch the sample!");
        NSLog(@"Serial: %@", serial);
    }
    else {
        Sample* sample = [results objectAtIndex:0];
        NSMutableSet* movies = [sample mutableSetValueForKey:@"movies"];
        NSEnumerator* movieenum = [movies objectEnumerator];
        NSLog(@"Movies: ");
        for( SampleMovie* movie in movieenum) {
            NSLog(@"%@",movie.path);
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPressed:(id)sender {
    [self performSegueWithIdentifier:@"Analyze" sender:self];
}
@end
