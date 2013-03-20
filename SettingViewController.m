//
//  SettingViewController.m
//  GGStorage
//
//  Created by lily on 3/11/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "SettingViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"

@interface SettingViewController ()
@property (nonatomic, retain) GTMOAuth2Authentication *driveService;
@end

//NSString *scope = @"https://photos.googleapis.com/data/feed/api/user"; // scope for Google+ API
//static NSString *const kKeychainItemName = @"Google Drive Quickstart";
//static NSString *const kClientID = @"81720981197.apps.googleusercontent.com";
//static NSString *const kClientSecret = @"EjZNvAXWx7D79EnvyHOpiw4W";

@implementation SettingViewController
@synthesize driveService;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

#pragma mark - Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/
#pragma mark - Table view delegate

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
    
    self.driveService = [[GTMOAuth2Authentication alloc] init];
    self.driveService = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    //   isGoogleAuth = [self isGoogleAuthorized];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UITableViewCell *googleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    Boolean isAuth = [self isGoogleAuthorized];
    if ([self isGoogleAuthorized]) {
        googleCell.detailTextLabel.text = @"Sign out";
    }else{
        googleCell.detailTextLabel.text = @"Sign in";
    }
    
    UITableViewCell *dropboxCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if ([[DBSession sharedSession] isLinked]) {
        dropboxCell.detailTextLabel.text = @"Sign out";
    }else{
        dropboxCell.detailTextLabel.text = @"Sign in";
    }
    
}


- (BOOL)isGoogleAuthorized
{
    return [(GTMOAuth2Authentication *)self.driveService canAuthorize];
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
        self.driveService = nil;
    }
    if (error == nil)
    {
        self.driveService = authResult;
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
#pragma mark - Table view data source


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
            GTMOAuth2ViewControllerTouch *viewController;
            viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:scope
                                                                        clientID:kClientID
                                                                    clientSecret:kClientSecret
                                                                keychainItemName:kKeychainItemName
                                                                        delegate:self
                                                                finishedSelector:@selector(viewController:finishedWithAuth:error:)];
            
            [[self navigationController] pushViewController:viewController
                                                   animated:YES];
            cell.detailTextLabel.text = @"Sign out";
        }else{
            //            NSMutableDictionary *keychainQuery = [self getKeychainQuery:kKeychainItemName];
            //            OSStatus junk = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
            //            NSAssert( junk == noErr , @"Problem deleting current dictionary." );
            //            NSAssert( junk == errSecItemNotFound, @"SecItemNotFound in current dictionary." );
            
                [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];


            [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.driveService];
            [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your Google account has been unlinked" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            cell.detailTextLabel.text = @"Sign in";
        }
    }
}


@end
