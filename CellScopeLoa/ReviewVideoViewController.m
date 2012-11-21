//
//  ReviewVideoViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "ReviewVideoViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Analysis.h"
#import "ResultsViewController.h"
dispatch_queue_t backgroundQueue;

@interface ReviewVideoViewController () {
    BOOL firstRun;
}
@end

@implementation ReviewVideoViewController

@synthesize program;
@synthesize loaLoaCounter;
@synthesize spinner;


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
    backgroundQueue = dispatch_queue_create("edu.berkeley.cellscope.analysisqueue", NULL);

	// Do any additional setup after loading the view.
    firstRun = YES;
}

- (void)viewDidAppear:(BOOL)animated
{

    if(firstRun) {
        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
        //This method inherit from UIView,show imagePicker with animation
        [self presentModalViewController:imagePickerController animated:YES];
        firstRun = NO;
        NSLog(@"firstrun");
    }
    else{
        NSLog(@"notfirstrun");
        //int width=[[UIScreen mainScreen] applicationFrame].size.width;
        //int height=[[UIScreen mainScreen] applicationFrame].size.height;
        //spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        //[spinner setCenter:CGPointMake(width/2.0, height/2.0)]; // I do this because I'm in landscape mode
        //[self.view addSubview:spinner];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        int width=[[UIScreen mainScreen] applicationFrame].size.width;
        int height=[[UIScreen mainScreen] applicationFrame].size.height;
        //spinner.center = CGPointMake(160, 240);
        [spinner setCenter:CGPointMake(width/2.0, height/2.0)];
        spinner.hidesWhenStopped = YES;
        
        [self.view addSubview:spinner];
        

        
        
        [spinner startAnimating];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"PickVideo"]) {
        UIImagePickerController* imagePickerController = segue.destinationViewController;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
    }
    if([segue.identifier isEqualToString:@"Review"]) {
        [spinner stopAnimating];
        ResultsViewController* rvc = (ResultsViewController*)[segue destinationViewController];
        rvc.backImage=self.resultsImage;
    }

}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //mike!
    NSURL* mediaURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    loaLoaCounter=[[Analysis alloc] init];
    
    //UIImage*result=[loaLoaCounter analyzeImagesNew:assetURL];
    dispatch_async(backgroundQueue, ^(void) {
        [loaLoaCounter analyzeImagesNew:mediaURL];
    });
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(eventHandler:)
     name:@"eventType"
     object:nil ];

    NSLog(@"Path: %@", [mediaURL absoluteString]);
    [self dismissModalViewControllerAnimated:YES];
}
-(void)eventHandler: (NSNotification *) notification
{
    NSLog(@"notification from analysis");
    self.resultsImage=[loaLoaCounter getOutImage];
    //[self dismissModalViewControllerAnimated:YES];
    [self performSegueWithIdentifier:@"Review" sender:self];
}


#pragma mark - When Tap Cancel

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

//Tells the delegate that the user picked an image. (Deprecated in iOS 3.0. Use imagePickerController:didFinishPickingMediaWithInfo: instead.)
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
