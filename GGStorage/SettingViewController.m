//
//  SettingViewController.m
//  GGStorage
//
//  Created by lily on 3/11/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "SettingViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"

@interface SettingViewController ()
//@property (nonatomic, retain) GTMOAuth2Authentication *driveService;

@end
static NSString *const kKeychainItemName = @"Google Drive Quickstart";
static NSString *const kClientID = @"81720981197.apps.googleusercontent.com";
static NSString *const kClientSecret = @"EjZNvAXWx7D79EnvyHOpiw4W";
@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            //            (__bridge id)kSecClassGenericPassword,
            //            (__bridge id)kSecClass,
            service,
            (__bridge id)kSecAttrService,
            service,
            (__bridge id)kSecAttrAccount,
            //            (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
            //            (__bridge id)kSecAttrAccessible,
            nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    //   isGoogleAuth = [self isGoogleAuthorized];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UITableViewCell *googleCell = [self.] .tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([self isGoogleAuthorized]) {
        googleCell.detailTextLabel.text = @"Sign out";
    }else{
        googleCell.detailTextLabel.text = @"Sign in";
    }
    
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    if ([[DBSession sharedSession] isLinked]) {
        dropboxCell.detailTextLabel.text = @"Sign out";
    }else{
        dropboxCell.detailTextLabel.text = @"Sign in";
    }
    
    
    //access dropbox
    //    NSURL *dropboxURL = [NSURL URLWithString:@"https://api.dropbox.com"];
    //    AFHTTPClient* dropboxClient = [[AFHTTPClient alloc] initWithBaseURL:dropboxURL];
    //    //we want to work with JSON-Data
    //    [dropboxClient setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    //
    //    // Initialize RestKit
    //    RKObjectManager *dropboxObjectManager = [[RKObjectManager alloc] initWithHTTPClient:dropboxClient];
    //    RKResponseDescriptor *dropboxResponseDescriptor = [RKResponseDescriptor
    //                                                       responseDescriptorWithMapping:nil
    //                                                       pathPattern:@"/1/oauth/request_token"
    //                                                       keyPath:nil
    //                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    //    [dropboxObjectManager addResponseDescriptor:dropboxResponseDescriptor];
    
    //    [dropboxObjectManager postObject: nil
    //                                path:@"/1/oauth/request_token"
    //                          parameters:nil
    //                             success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
    //                                 NSArray* statuses = [mappingResult array];
    //                                 NSLog(@"Loaded statuses: %@", statuses);
    //                             }
    //                             failure:^(RKObjectRequestOperation *operation, NSError *error) {
    //                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
    //                                                                                 message:[error localizedDescription]
    //                                                                                delegate:nil
    //                                                                       cancelButtonTitle:@"OK"
    //                                                                       otherButtonTitles:nil];
    //                                 [alert show];
    //                                 NSLog(@"Hit error: %@", error);
    //                             }];
    //    [dropboxObjectManager getObjectsAtPath:@"/1/account/info"
    //                          parameters:nil
    //                             success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
    //                                 NSArray* statuses = [mappingResult array];
    //                                 NSLog(@"Loaded statuses: %@", statuses);
    //                             }
    //                             failure:^(RKObjectRequestOperation *operation, NSError *error) {
    //                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
    //                                                                                 message:[error localizedDescription]
    //                                                                                delegate:nil
    //                                                                       cancelButtonTitle:@"OK"
    //                                                                       otherButtonTitles:nil];
    //                                 [alert show];
    //                                 NSLog(@"Hit error: %@", error);
    //                             }];
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    
    NSArray *secItemClasses = [NSArray arrayWithObjects:
                               (__bridge id)kSecClassGenericPassword,
                               //                               (__bridge id)kSecClassInternetPassword,
                               //                               (__bridge id)kSecClassCertificate,
                               //                               (__bridge id)kSecClassKey,
                               //                               (__bridge id)kSecClassIdentity,
                               nil];
    //    NSMutableDictionary *keychainQuery = [self getKeychainQuery:kKeychainItemName];
    //    OSStatus junk = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    for (id secItemClass in secItemClasses) {
        NSLog(@"%@", kSecClass);
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];
        
        CFTypeRef result = NULL;
        //        SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, &result);
        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        
        NSLog(@"result %@", (__bridge id)result);
        if (result != NULL) CFRelease(result);
    }
    NSMutableDictionary *keychainData = [[NSMutableDictionary alloc] init];
    
    //    NSMutableDictionary *tmpDictionary =[self dictionaryToSecItemFormat:keychainData];
    // Delete the keychain item in preparation for resetting the values:
    //    SecItemDelete((CFDictionaryRef)tmpDictionary);
    
    //    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.dropbox.com/1/oauth/request_token"]];
    //    [request setHTTPMethod:@"POST"];
    //    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //    NSString *get = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@",get);
}


- (BOOL)isGoogleAuthorized
{
    return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
}

// Creates the auth controller for authorizing access to Googel Drive.
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
    if (error == nil)
    {
        self.driveService.authorizer = authResult;
        UITableViewCell *googleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if ([self isGoogleAuthorized]) {
            googleCell.detailTextLabel.text = @"Sign out";
        }else{
            googleCell.detailTextLabel.text = @"Sign in";
        }
        
    }
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
 {
 #warning Potentially incomplete method implementation.
 // Return the number of sections.
 return 2;
 }
 
 - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
 {
 #warning Incomplete method implementation.
 // Return the number of rows in the section.
 return 4+section;
 }
 
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 static NSString *CellIdentifier = @"Cell";
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqual: @"Dropbox"]) {
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:self];
            //            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.dropbox.com/1/oauth/authorize"]];
            //            [request setHTTPMethod:@"GET"];
            //            NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            //            NSString *get = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            ////            NSLog(@"%@",get);
            //            UIWebView *webView = [[UIWebView alloc]init];
            //            UIViewController *authVC = [[UIViewController alloc]init];
            //            authVC.view = webView;
            //            [webView loadRequest:request];
            //  //          [webView loadHTMLString:get baseURL:[NSURL URLWithString:@"https://www.dropbox.com/1/oauth/authorize"]];
            //            UINavigationController *nav = self.navigationController;
            //            [nav pushViewController:authVC animated:YES];
            cell.detailTextLabel.text = @"Sign out";
            //
        } else {
            [[DBSession sharedSession] unlinkAll];
            [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            //[self updateButtons];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            cell.detailTextLabel.text = @"Sign in";
        }
    }
    if ([cell.textLabel.text isEqual:@"Google"]) {
        if (![self isGoogleAuthorized]) {
            UINavigationController *nav = self.navigationController;
            [nav pushViewController:[self createAuthController] animated:YES];
            cell.detailTextLabel.text = @"Sign out";
        }else{
            //            NSMutableDictionary *keychainQuery = [self getKeychainQuery:kKeychainItemName];
            //            OSStatus junk = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
            //            NSAssert( junk == noErr , @"Problem deleting current dictionary." );
            //            NSAssert( junk == errSecItemNotFound, @"SecItemNotFound in current dictionary." );
            
            //            [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
            [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.driveService.authorizer];
            [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your Google account has been unlinked" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            cell.detailTextLabel.text = @"Sign in";
        }
    }
}
@end
