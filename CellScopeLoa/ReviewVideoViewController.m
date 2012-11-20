//
//  ReviewVideoViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 11/19/12.
//  Copyright (c) 2012 Matthew Bakalar. All rights reserved.
//

#import "ReviewVideoViewController.h"

@interface ReviewVideoViewController () {
    BOOL firstRun;
}

@end

@implementation ReviewVideoViewController

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
	// Do any additional setup after loading the view.
    firstRun = YES;
}

- (void)viewDidAppear:(BOOL)animated
{

    if(firstRun) {
        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //This method inherit from UIView,show imagePicker with animation
        [self presentModalViewController:imagePickerController animated:YES];
        firstRun = NO;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"PickVideo"]) {
        UIImagePickerController* imagePickerController = segue.destinationViewController;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.delegate = self;
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL* mediaURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSLog(@"Path: %@", [mediaURL absoluteString]);
    [self dismissModalViewControllerAnimated:YES];
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
