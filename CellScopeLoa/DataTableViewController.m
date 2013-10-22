//
//  DataTableViewController.m
//  CellScopeLoa
//
//  Created by Matthew Bakalar on 7/1/13.
//  Copyright (c) 2013 Matthew Bakalar. All rights reserved.
//

#import "DataTableViewController.h"
#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Sample.h"
#import "SampleMovie.h"
#import "ImageThumbCell.h"
#import "DataReviewImagesViewController.h"
#import "CountViewController.h"
#import "SampleExporter.h"
#import "Reachability.h"

static NSString *const kKeychainItemName = @"Google Drive Quickstart";
static NSString *const kClientID = @"822665295778.apps.googleusercontent.com";
static NSString *const kClientSecret = @"mbDjzu2hKDW23QpNJXe_0Ukd";

@interface DataTableViewController ()

@end

@implementation DataTableViewController {
    NSEnumerator* sampleEnumerator;
}

@synthesize managedObjectContext;
@synthesize lastSelectedIndex;
@synthesize driveService;
@synthesize loginButton;

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
    
    // Initialize the drive service & load existing credentials from the keychain if available
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                         clientID:kClientID
                                                                                     clientSecret:kClientSecret];
    
    // Log out of any google credentials we have
    if([self isAuthorized]) {
        loginButton.title = @"Logout";
        // [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        // [[self driveService] setAuthorizer:nil];
    }
    else {
        loginButton.title = @"Login";
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadSamples];
    [self isAuthorized];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self isAuthorized];
}

- (void)loadSamples
{
    NSError *error;
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"capturetime" ascending:NO];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sample"
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    self.samples = fetchedObjects;
    sampleEnumerator = [self.samples objectEnumerator];
    //[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.samples == nil) {
        return 0;
    }
    else {
        return [self.samples count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ResultsCell";
    ImageThumbCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[ImageThumbCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    Sample *sample = (Sample*)[self.samples objectAtIndex:indexPath.row];
    
    // Configure datetime
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"dd/MM/YYYY HH:mm"];
    NSString *dateString = [dateFormat stringFromDate:sample.capturetime];
    
    // Configure thumbnail
    NSSet* movies = sample.movies;
    NSEnumerator* enumerator = movies.objectEnumerator;
    SampleMovie *firstmovie = (SampleMovie*)[enumerator nextObject];
        
    // Retrieve the thumbnail
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        if (iref) {
            cell.thumbnail.image = [UIImage imageWithCGImage:iref];
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"Cant get image - %@",[myerror localizedDescription]);
    };
    
    NSURL *asseturl = [NSURL URLWithString:firstmovie.processedimagepath];
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:asseturl
                   resultBlock:resultblock
                   failureBlock:failureblock];
        
    cell.mainLabel.text = dateString;
    cell.detailLabel.text = sample.username;
    
    if(sample.synced.boolValue == NO)
    {
        cell.syncIcon.hidden = YES;
    }
    else {
        cell.syncIcon.hidden = NO;
    }
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"ViewSample"]) {
        UITabBarController* tc = [segue destinationViewController];
        DataReviewImagesViewController* ivc = (DataReviewImagesViewController*)[[tc customizableViewControllers] objectAtIndex:0];
        CountViewController* cvc = (CountViewController*)[[tc customizableViewControllers] objectAtIndex:1];
        Sample* currentSample = (Sample*)[self.samples objectAtIndex:lastSelectedIndex.integerValue];
        ivc.sample = currentSample;
        cvc.sample = currentSample;
    }
}


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
    lastSelectedIndex = [NSNumber numberWithInt:indexPath.row];
    [self performSegueWithIdentifier:@"ViewSample" sender:self];
}

#pragma mark - Google Drive
// Creates the auth controller for authorizing access to Google Drive.
- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Helper to check if user is authorized
- (BOOL)isAuthorized
{
    BOOL authorized = [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
    if(authorized) {
        loginButton.title = @"Logout";
    }
    else {
        loginButton.title = @"Login";
    }
    return authorized;
}

- (IBAction)loginButtonPressed:(id)sender {
    if (![self isAuthorized])
    {
        // Not yet authorized, request authorization and push the login UI onto the navigation stack.
        [self presentViewController:[self createAuthController] animated:YES completion:^{
            // Pass
        }];
    }
    else {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        [[self driveService] setAuthorizer:nil];
        loginButton.title = @"Login";
    }
}

- (IBAction)onExport:(id)sender {
    if ([self networkIsReachable]) {
        if (![self isAuthorized])
        {
            // Not yet authorized, request authorization and push the login UI onto the navigation stack.
            [self presentViewController:[self createAuthController] animated:YES completion:^{
                [self showAlert:@"Action" message:@"Please log in, then press sync again"];
            }];
        }
        else {
            // First, upload the database text file representation
            NSString* datarep = [SampleExporter databaseString:self.samples];
            [self syncDatabaseText:datarep];
            [self uploadSamples];
        }
    }
    else {
        [self showAlert:@"Network error" message:@"Wifi is not available."];
    }
}

// Handle completion of the authorization process, and updates the Drive service
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error
{
    if (error != nil)
    {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.driveService.authorizer = nil;
    }
    else
    {
        self.driveService.authorizer = authResult;
    }
    [self dismissViewControllerAnimated:viewController completion:nil];
}

// Helper for showing a wait indicator in a popup
- (UIAlertView*)showWaitIndicator:(NSString *)title
{
    UIAlertView *progressAlert;
    progressAlert = [[UIAlertView alloc] initWithTitle:title
                                               message:@"Please wait..."
                                              delegate:nil
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil];
    [progressAlert show];
    
    UIActivityIndicatorView *activityView;
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.center = CGPointMake(progressAlert.bounds.size.width / 2,
                                      progressAlert.bounds.size.height - 45);
    
    [progressAlert addSubview:activityView];
    [activityView startAnimating];
    return progressAlert;
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
}

// Uploads a video to Google Drive
- (void)uploadVideo:(NSData*)data withName:(NSString*)name
{
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = name;
    file.descriptionProperty = @"Uploaded from the Google Drive iOS Quickstart";
    file.mimeType = @"video/mov";
    
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];
    
    UIAlertView *waitIndicator = [self showWaitIndicator:@"Uploading to Google Drive"];
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *insertedFile, NSError *error) {
                      [waitIndicator dismissWithClickedButtonIndex:0 animated:YES];
                      if (error == nil)
                      {
                          NSLog(@"File ID: %@", insertedFile.identifier);
                          // [self showAlert:@"Google Drive" message:@"File saved!"];
                      }
                      else
                      {
                          NSLog(@"An error occurred: %@", error);
                          [self showAlert:@"Google Drive" message:@"Sorry, an upload error occurred!"];
                      }
                  }];
}

- (void)movieUploadBlock:(NSEnumerator*)movieEnumerator withMovie:(SampleMovie*)movie Sample:(Sample*)sample movNum:(NSNumber*)movnum completion:(void (^)(void))block;
{
    NSLog(@"Upload movie num: %d", movnum.intValue);
    NSURL* url = [NSURL URLWithString:movie.path];
    AVAsset *video = [AVURLAsset URLAssetWithURL:url options:nil];
    NSArray *keys = @[@"tracks", @"duration"];
    [video loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
        
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [video statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
                break;
            case AVKeyValueStatusFailed:
                break;
            case AVKeyValueStatusCancelled:
                // Do whatever is appropriate for cancelation.
                break;
        }
    
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:video];
        if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                                   initWithAsset:video presetName:AVAssetExportPreset960x540];
            NSString *tempName = [NSString stringWithFormat:@"%@_%d.mov", sample.serialnumber, movnum.intValue];
            NSString *tempFileTemplate = [NSTemporaryDirectory()
                                          stringByAppendingPathComponent:tempName];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:tempFileTemplate]) {
                NSError *error;
                if ([fileManager removeItemAtPath:tempFileTemplate error:&error] == NO) {
                    NSLog(@"removeItemAtPath %@ error:%@", tempFileTemplate, error);
                }
            }
            
            exportSession.outputURL = [NSURL fileURLWithPath:tempFileTemplate];
            exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                switch ([exportSession status]) {
                    case AVAssetExportSessionStatusCompleted:
                    {
                        
                        NSData *data = [NSData dataWithContentsOfFile:tempFileTemplate];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                            GTLDriveFile *file = [GTLDriveFile object];
                            file.title = tempName;
                            file.mimeType = @"video/mov";
                            
                            GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
                            GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                                               uploadParameters:uploadParameters];
                            
                            UIAlertView *waitIndicator = [self showWaitIndicator:@"Uploading video to Google Drive"];
                            
                            [self.driveService executeQuery:query
                                          completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFile *insertedFile, NSError *error) {
                                              [waitIndicator dismissWithClickedButtonIndex:0 animated:YES];
                                              if (error == nil)
                                              {
                                                  NSLog(@"File ID: %@", insertedFile.identifier);
                                                  // [self showAlert:@"Google Drive" message:@"File saved!"];
                                              }
                                              else
                                              {
                                                  NSLog(@"An error occurred: %@", error);
                                                  [self showAlert:@"Google Drive" message:@"Sorry, an error occurred!"];
                                              }
                                              
                                              // Launch the next movie upload
                                              SampleMovie* movie = [movieEnumerator nextObject];
                                              if (movie != nil) {
                                                  NSNumber* nextnum = [NSNumber numberWithInt:(movnum.intValue+1)];
                                                  [self movieUploadBlock:movieEnumerator withMovie:movie Sample:sample movNum:nextnum completion:block];
                                              }
                                              else {
                                                  // Update item as synced
                                                  sample.synced = [NSNumber numberWithBool:YES];
                                                  NSError *error = nil;
                                                  [self.managedObjectContext save:&error];  //saves the context to disk
                                                  [self.tableView reloadData];
                                                  // Run completion block
                                                  block();
                                              }
                                              
                                          }];

                        }];
                        break;
                    }
                    case AVAssetExportSessionStatusWaiting:
                        NSLog(@"Export Waiting");
                        break;
                    case AVAssetExportSessionStatusExporting:
                        NSLog(@"Export Exporting");
                        break;
                    case AVAssetExportSessionStatusFailed:
                    {
                        NSError *error = [exportSession error];
                        NSLog(@"Export failed: %@", [error localizedDescription]);
                        break;
                    }
                    case AVAssetExportSessionStatusCancelled:
                        NSLog(@"Export canceled");
                        break;
                    default:
                        break;
                }
                
            }];
        }
    }];
}

// Upload all samples that have not been marked synced
- (void)uploadSamples
{
    Sample *sample = [sampleEnumerator nextObject];
    if(sample != nil) {
        NSLog(@"Upload next sample");
        if(sample.synced.boolValue == NO) {
            NSNumber* movnum = [NSNumber numberWithInt:0];
            NSEnumerator *movieEnumerator = [sample.movies objectEnumerator];
            SampleMovie* movie = [movieEnumerator nextObject];
            [self movieUploadBlock:movieEnumerator withMovie:movie Sample:sample movNum:movnum completion:^{
                [self uploadSamples];
            }];
        }
    }
}

- (void)syncDatabaseText:(NSString*)text
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* deviceID = (NSString*)[defaults objectForKey:@"DeviceID"];
    
    NSData *fileContent = [text dataUsingEncoding:NSUTF8StringEncoding];
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:fileContent MIMEType:@"text/plain"];
    
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = [NSString stringWithFormat:@"%@-database.txt", deviceID];
    GTLQueryDrive *query = nil;
    // This is a new file, instantiate an insert query.
    query = [GTLQueryDrive queryForFilesInsertWithObject:file uploadParameters:uploadParameters];

    UIAlertView *waitIndicator = [self showWaitIndicator:@"Uploading database record"];
    
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFile *updatedFile,
                                                              NSError *error) {
        [waitIndicator dismissWithClickedButtonIndex:0 animated:YES];
        if (error == nil) {
            // pass
        } else {
            NSLog(@"An error occurred: %@", error);
            [self showAlert:@"Error" message:@"Unable to save database file. Check internet connection and try again later."];
        }
    }];
}

-(BOOL)networkIsReachable
{
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    if (internetStatus == ReachableViaWiFi) {
        return YES;
    }
    else {
        return NO;
    }
}

- (IBAction)donePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:Nil];
}

@end
