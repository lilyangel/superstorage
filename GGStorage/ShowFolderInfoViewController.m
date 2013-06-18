//
//  ShowFolderInfoViewController.m
//  GGStorage
//
//  Created by lily on 3/26/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "ShowFolderInfoViewController.h"

#import <DropboxSDK/DropboxSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "GoogleAuth.h"
#import "PhotoFullScreenViewController.h"

@interface ShowFolderInfoViewController ()
@property GDataServiceGooglePhotos *googlePhotoService;
@property NSArray *currentGoogleList;
@property NSArray *currentDropboxList;
@property DBRestClient *dropboxClient;
@property UILabel *nav_title;
@property UITableView *tableView;
@property UIRefreshControl *refreshControl;
@property UIToolbar *toolBar;
@property GDataServiceGoogle *gdataServiceGoogle;
@property GTMOAuth2Authentication *googleAuth;
@end

@implementation ShowFolderInfoViewController
@synthesize folderInfo = _folderInfo;
@synthesize mediaType = _mediaType;
@synthesize googlePhotoService = _googlePhotoService;
@synthesize currentGoogleList = _currentGoogleList;
@synthesize currentDropboxList = _currentDropboxList;
@synthesize dropboxClient = _dropboxClient;
@synthesize nav_title = _nav_title;
@synthesize tableView;
@synthesize refreshControl;
@synthesize showFullPhoto;
@synthesize toolBar = _toolBar;
@synthesize googleCurrentList = _googleCurrentList;
@synthesize dropboxCurrentList = _dropboxCurrentList;
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

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self googlePhotosService];
    _googlePhotoService = [GoogleAuth getGooglePhotoService];
    [self dropboxClient];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (_mediaType == 0) {
        GDataEntryPhotoAlbum* album = _folderInfo;
        NSURL *feedURL = [[album feedLink] URL];
        if (feedURL) {
            GDataServiceTicket *ticket;
            ticket = [_googlePhotoService fetchFeedWithURL:feedURL
                                                  delegate:self
                                         didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
        }
    }
    if (_mediaType == 1) {
        DBMetadata *folder = _folderInfo;
        NSLog(@"%@", folder.path);
        [_dropboxClient loadMetadata:folder.path];
    }
    if(_currentFile){
        float toolBarHeight = 44;
        self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-toolBarHeight-self.navigationController.navigationBar.frame.size.height)];
        _toolBar = [[UIToolbar alloc] init];
        _toolBar.frame = CGRectMake(0, self.tableView.frame.size.height, self.tableView.frame.size.width, toolBarHeight);
        _toolBar.barStyle = UIBarStyleBlack;
        _toolBar.items = [self createButtons];
        [self.view addSubview:_toolBar];
    }
    else{
        self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(handleRefresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

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
    if (_mediaType == 0) {
        NSString *username = _googleAuth.userEmail;
        GDataEntryBase *photo = _currentFile;
        GDataEntryPhotoAlbum *folder = _folderInfo;
        NSLog(@"%@",[photo.editLink URL]);
//        NSLog(@"%@",photo.albumID);
//        NSLog(@"%@",photo.albumTitle);
        NSArray *folderInfo = [folder.identifier componentsSeparatedByString:@"albumid/"];
        NSString *folderId = [folderInfo objectAtIndex:1];
        NSLog(@"%@",folderId);
//        [photo setAlbumID:folderId];
        if (username.length) {
//            GDataServiceTicket *ticket = [_gdataServiceGoogle fetchEntryByUpdatingEntry:photo
//                                                                               delegate:self
//                                                                      didFinishSelector:@selector(updatedTicket:finishedWithFeed:error:)];
            GDataServiceTicket *tt = [_gdataServiceGoogle fetchEntryByUpdatingEntry:photo completionHandler:^(GDataServiceTicket *ticket, GDataEntryBase *entry, NSError *error) {
                
            }];
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

-(void)handleRefresh
{
    [self.refreshControl beginRefreshing];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    _currentDropboxList = metadata.contents;
    [self.tableView reloadData];
}

- (UILabel*)configLabel:(UILabel*)label
{
    label.font = [UIFont fontWithName:@"Arial-BoldMT" size:18];
    label.textColor = [UIColor whiteColor];
    label.adjustsFontSizeToFitWidth = YES;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

-(void) viewWillAppear:(BOOL)animated
{
    for (NSObject *subview in [self.navigationController.navigationBar subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            _nav_title = (UILabel*) subview;

        }
    }
    if (_nav_title == nil) {
        _nav_title = [[UILabel alloc] initWithFrame:CGRectMake(80, 2, 220, 25)];
        _nav_title = [self configLabel:_nav_title];
        [self.navigationController.navigationBar addSubview:_nav_title];
    }
    if (_mediaType == 0) {
        GDataEntryPhotoAlbum *album = _folderInfo;
        _nav_title.text = [[[album mediaGroup]mediaTitle]stringValue];
    }
    if (_mediaType == 1) {
        DBMetadata* folder = _folderInfo;
        _nav_title.text = folder.filename;
        NSLog(@"%@",_nav_title);
    }
}

- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error
{
    _currentGoogleList = [feed entries];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
//    if ([_currentGoogleList count]!=0) {
//        return 1;
//    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
//    switch (section) {
//        case 0:
//            return [_currentGoogleList count];
//            break;
//            
//        default:
//            break;
//    }
    if (_mediaType == 0) {
        return [_currentGoogleList count];
    }
    if (_mediaType == 1) {
        return [_currentDropboxList count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    if (_mediaType == 0) {
        GDataEntryPhoto *photo = [_currentGoogleList objectAtIndex:indexPath.row];
        cell.textLabel.text = [[[photo mediaGroup]mediaTitle]stringValue];
    }
    if(_mediaType == 1) {
        DBMetadata *dropboxItem = [_currentDropboxList objectAtIndex:indexPath.row];
        cell.textLabel.text = dropboxItem.filename;
    }

    return cell;
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    if (_mediaType == 0) {
        PhotoFullScreenViewController *photoFullScreenVC = [[PhotoFullScreenViewController alloc]init];
        photoFullScreenVC.googlePhotos = _currentGoogleList;
        photoFullScreenVC.photoIndex = indexPath.row;
        [photoFullScreenVC setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:photoFullScreenVC animated:YES];
    }
    if (_mediaType == 1) {
        DBMetadata *dropboxItem = [_currentDropboxList objectAtIndex:indexPath.row];
        if (dropboxItem.isDirectory) {
            ShowFolderInfoViewController *folderInfoVC = [[ShowFolderInfoViewController alloc]init];
            folderInfoVC.folderInfo = [_currentDropboxList objectAtIndex:indexPath.row];
            folderInfoVC.mediaType = 1;
            [self.navigationController pushViewController:folderInfoVC animated:YES];
        }else{
            PhotoFullScreenViewController *photoFullScreenVC = [[PhotoFullScreenViewController alloc]init];
            NSMutableArray *dropboxPhotos = [[NSMutableArray alloc]init];
            NSString* fileSuffix = [[dropboxItem.filename componentsSeparatedByString:@"."] lastObject];
            
            if([fileSuffix isEqual:@"rtf"]||[fileSuffix isEqual:@"pdf"]){
                NSArray *dropboxItems = [[NSArray alloc]initWithObjects:dropboxItem, nil];
                photoFullScreenVC.dropboxPhotos = dropboxItems;
                photoFullScreenVC.photoIndex = 0;
                
            }else{
                for (DBMetadata *dbItem in _currentDropboxList) {
                    [dropboxPhotos addObject:dbItem];
                }
                photoFullScreenVC.dropboxPhotos = dropboxPhotos;
                photoFullScreenVC.photoIndex = indexPath.row;
            }
            [photoFullScreenVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:photoFullScreenVC animated:YES];
        }
    }
}

@end
