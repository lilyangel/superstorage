//
//  RootFoldersViewController.m
//  GGStorage
//
//  Created by lily on 3/27/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "RootFoldersViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"
#import <DropboxSDK/DropboxSDK.h>
#import "PhotoFullScreenViewController.h"
#import "ShowFolderInfoViewController.h"
#import "GoogleAuth.h"

@interface RootFoldersViewController ()
//@property NSMutableArray *googleCurrentList;
//@property NSMutableArray *dropboxCurrentList;
@property GDataServiceGooglePhotos *googlePhotoService;
@property DBRestClient *dropboxClient;
@property UITableView *tableView;
@property UIRefreshControl *refreshControl;
@property UIToolbar *toolBar;
@property GDataEntryPhotoAlbum *currentGoogleFolder;
@property GDataServiceGoogle *gdataServiceGoogle;
@property GTMOAuth2Authentication *googleAuth;
@end

@implementation RootFoldersViewController
@synthesize googleCurrentList = _googleCurrentList;
@synthesize dropboxCurrentList = _dropboxCurrentList;
@synthesize googlePhotoService = _googlePhotoService;
@synthesize dropboxClient = _dropboxClient;
@synthesize mediaType = _mediaType;
@synthesize showFullPhoto = _showFullPhoto;
@synthesize tableView;
@synthesize refreshControl;
@synthesize toolBar = _toolBar;
@synthesize currentGoogleFolder = _currentGoogleFolder;
@synthesize currentFile = _currentFile;
@synthesize googleAuth = _googleAuth;
@synthesize gdataServiceGoogle = _gdataServiceGoogle;

- (GDataServiceGoogle *)googlePhotosService {
    
    //    static GDataServiceGooglePhotos* service = nil;
    
    if (!_gdataServiceGoogle) {
        _gdataServiceGoogle = [[GDataServiceGoogle alloc] init];
        
        [_gdataServiceGoogle setShouldCacheResponseData:YES];
        [_gdataServiceGoogle setServiceShouldFollowNextLinks:YES];
    }
    _googleAuth = [[GTMOAuth2Authentication alloc] init];
    _googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    [_gdataServiceGoogle setAuthorizer:_googleAuth];
    
    return _gdataServiceGoogle;
}

- (DBRestClient *)dropboxClient {
    if (!_dropboxClient) {
        if (![DBSession sharedSession]) {
            return nil;
        }
        _dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dropboxClient.delegate = self;
    }
    return _dropboxClient;
}

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    _googlePhotoService = [GoogleAuth getGooglePhotoService];
//    [self dropboxClient];
//    NSString *username = [GoogleAuth getGoogleAuth].userEmail;
//    if (username.length) {
//        NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
//                                                                 albumID:nil
//                                                               albumName:nil
//                                                                 photoID:nil
//                                                                    kind:nil
//                                                                  access:nil];
//        
////        GDataServiceTicket *ticket = [_googlePhotoService fetchFeedWithURL:feedURL
////                                                                  delegate:self
////                                                         didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
//    }
//    [_dropboxClient loadMetadata:@"/" withHash:nil];
    [self gdataServiceGoogle];
    float toolBarHeight = 44;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-toolBarHeight-self.navigationController.navigationBar.frame.size.height)];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(handleRefresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _toolBar = [[UIToolbar alloc] init];
    _toolBar.frame = CGRectMake(0, self.tableView.frame.size.height, self.tableView.frame.size.width, toolBarHeight);
    _toolBar.barStyle = UIBarStyleBlack;
    _toolBar.items = [self createButtons];
    [self.view addSubview:_toolBar];
}

- (NSArray*)createButtons
{
    //add permission button
    UIButton *movedButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, _toolBar.frame.size.width-20*2, 30)];
    [movedButton setTitle:@"Move to this folder" forState:UIControlStateNormal];
    [movedButton addTarget:self action:@selector(moveToNewFolder) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *movedItem = [[UIBarButtonItem alloc] initWithCustomView:movedButton];
    
    NSArray *barButtonItems = [NSArray arrayWithObjects:movedItem, nil];
    return barButtonItems;
}

-(void)moveToNewFolder
{
    if (_googleCurrentList) {
        NSString *username = _googleAuth.userEmail;
        GDataEntryPhoto *photo = _currentFile;
        NSLog(@"%@",photo.albumID);
        [photo setAlbumID:nil];
        if (username.length) {
            GDataServiceTicket *ticket = [_gdataServiceGoogle fetchEntryByUpdatingEntry:photo
                                                                               delegate:self
                                                                      didFinishSelector:@selector(updatedTicket:finishedWithFeed:error:)];
        }
    }
}

- (void)updatedTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedPhotoAlbum *)feed
                error:(NSError *)error
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't move to this folder!"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
//    [self.navigationItem setHidesBackButton:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
//    switch (section) {
//        case 0: return [_googleCurrentList count];
//        case 1: return [_dropboxCurrentList count];
//        default: return 1;
//    }
    if (_googleCurrentList) {
        return [_googleCurrentList count];
    }else if(_dropboxCurrentList){
        return [_dropboxCurrentList count];
    }else{
        return 1;
    }
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *sectionName;
//    switch (section) {
//        case 0:
//            if ([_googleCurrentList count]!=0) {
//                sectionName = @"google drive";
//            }
//            break;
//        case 1:
//            if ([_dropboxCurrentList count]!=0) {
//                sectionName = @"dropbox";
//            }
//        default:
//            break;
//    }
//    
//    return sectionName;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
//    if (indexPath.section == 0) {
//        GDataEntryPhoto *photo = [_googleCurrentList objectAtIndex:indexPath.row];
//        cell.textLabel.text = [[[photo mediaGroup]mediaTitle]stringValue];
//    }
//    if (indexPath.section == 1) {
//        DBMetadata *photo = [_dropboxCurrentList objectAtIndex:indexPath.row];
//        cell.textLabel.text = photo.filename;
//    }
    if (_googleCurrentList) {
        GDataEntryPhoto *photo = [_googleCurrentList objectAtIndex:indexPath.row];
        cell.textLabel.text = [[[photo mediaGroup]mediaTitle]stringValue];
    }else if(_dropboxCurrentList){
        DBMetadata *photo = [_dropboxCurrentList objectAtIndex:indexPath.row];
        cell.textLabel.text = photo.filename;
    }
    return cell;
}

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
    
    if(_googleCurrentList){
        ShowFolderInfoViewController *listVC = [[ShowFolderInfoViewController alloc]init];
        listVC.mediaType = 0;
        listVC.folderInfo = [_googleCurrentList objectAtIndex:indexPath.row];
        listVC.currentFile = _currentFile;
        [self.navigationController pushViewController:listVC animated:YES];
    }
    if(_dropboxCurrentList){
        DBMetadata *item = [_dropboxCurrentList objectAtIndex:indexPath.row];
        if (item.isDirectory) {
            ShowFolderInfoViewController *folderInfoVC = [[ShowFolderInfoViewController alloc]init];
            folderInfoVC.folderInfo = item;
            folderInfoVC.mediaType = 1;
            [self.navigationController pushViewController:folderInfoVC animated:YES];
        }else{
            PhotoFullScreenViewController *photoFullScreenVC = [[PhotoFullScreenViewController alloc]init];
            NSMutableArray *dropboxPhotos = [[NSMutableArray alloc]init];
            for (DBMetadata *dbItem in _dropboxCurrentList) {
                NSArray *file = [dbItem.filename componentsSeparatedByCharactersInSet:@"."];
                NSString *fileType = [file objectAtIndex:[file count]-1];
                
                //               if ([imageSuffix containsObject:fileType]) {
                [dropboxPhotos addObject:dbItem];
                //                }
            }
            photoFullScreenVC.dropboxPhotos = dropboxPhotos;
            photoFullScreenVC.photoIndex = indexPath.row;
            [photoFullScreenVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:photoFullScreenVC animated:YES];
        }
    }
}


@end
