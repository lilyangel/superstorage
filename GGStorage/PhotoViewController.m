//
//  PhotoViewController.m
//  GGStorage
//
//  Created by lily on 3/12/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "PhotoViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"
#import <DropboxSDK/DropboxSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "ThumbnailLineInfo.h"
#import "ShowFolderInfoViewController.h"
#import "RootFoldersViewController.h"

//#import "DropboxServiceClient.h"
static NSArray *imageSuffix;
@interface PhotoViewController ()<DBRestClientDelegate, UITableViewDelegate, UITableViewDataSource>//
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
//@property GDataFeedPhotoAlbum *mAlbumPhotosFeed;
//@property GDataFeedPhotoUser *mUserAlbumFeed;
@property (nonatomic, retain) GTMOAuth2Authentication *googleAuth;
@property NSMutableArray* photoThumbnails;
@property int photoCount;
@property int photosPerBlock;
@property int columns;
//@property int thumbnailPhotoIndex;
//@property int dropboxThumbnailPage;
//@property int googleThumbnailIndex;
//Dropbox client
@property DBRestClient *dropClient;
@property NSString* documentDir;
@property int currentMaxPhotoIndex;
@property NSMutableDictionary* googleThumbnails;
@property NSMutableArray *thumbnailLine;
@property int photoIndexBegin;
@property int photoIndexEnd;
@property float imageHeight;
//@property float imageWidth;
@property NSMutableArray *imageViews;
@property NSMutableArray *googlePhotos;
@property int googlePhotosCount;
@property NSLock *google_photos_lock;
@property NSLock *googleThumbnails_lock;
@property NSLock *photoDisplay;
@property int googleFetchCount;
@property int googleFetchEndCount;
@property GDataServiceGooglePhotos *googlePhotoService;
@property float scrollBeginOffset;
@property float scrollEndOffset;
@property int photosIndex;
@property NSCondition *fetchGooglePhotosLock;
@property Boolean isDisplay;
@property int currentBlock;
@property (nonatomic, strong) UITapGestureRecognizer *subImageTap;
@property int tappedPhotoId;
@property NSMutableDictionary *dropboxThumbnailDestAndIndex;
@property int dropboxFetchCount;
@property int dropboxFetchEndCount;
@property NSMutableDictionary *dropboxThumbnails;
//1 : googleDrive
//2 : dropbox;
@property int mediaType;
@property int dropboxErrorCountPerblock;
//YES: thumbnailView
//NO: FolderView
@property Boolean isThumbnailViews;
@property UIButton *viewFormatButton;
@property UITableView *tableView;
@property NSMutableArray* googleCurrentList;
@property NSMutableArray* dropboxCurrentList;
@property Boolean isDropboxRoot;
@property UIRefreshControl *refreshControl;
@property UIAlertView *downloadAlert;
@property int googleAlbumsCount;
@property int googleAlbumsSum;
@end

@implementation PhotoViewController
//@synthesize mAlbumPhotosFeed;
@synthesize scrollView = _scrollView;
@synthesize googleAuth = _googleAuth;
@synthesize photoThumbnails = _photoThumbnails;
@synthesize dropClient = _dropClient;
@synthesize photoCount = _photoCount;
@synthesize documentDir = _documentDir;
//@synthesize thumbnailPhotoIndex = _thumbnailPhotoIndex;
@synthesize photosPerBlock = _photoPerBlock;
@synthesize columns = _columns;
//@synthesize mUserAlbumFeed = _mUserAlbumFeed;
//@synthesize dropboxThumbnailPage = _dropboxThumbnailPage;
//@synthesize googleThumbnailIndex = _googleThumbnailIndex;
@synthesize googleThumbnails = _googleThumbnails;
@synthesize thumbnailLine = _thumbnailLine;
@synthesize photoIndexBegin = _photoIndexBegin;
@synthesize photoIndexEnd = _photoIndexEnd;
@synthesize imageHeight = _imageHeight;
//@synthesize imageWidth = _imageWidth;
@synthesize currentMaxPhotoIndex = _currentMaxPhotoIndex;
@synthesize imageViews = _imageViews;
@synthesize googlePhotos = _googlePhotos;
@synthesize googlePhotosCount = _googlePhotosCount;
@synthesize google_photos_lock = _google_photos_lock;
@synthesize googleFetchCount = _googleFetchCount;
@synthesize googleFetchEndCount = _googleFetchEndCount;
@synthesize googlePhotoService = _googlePhotoService;
@synthesize scrollBeginOffset = _scrollBeginOffset;
@synthesize scrollEndOffset = _scrollEndOffset;
@synthesize photosIndex = _photosIndex;
@synthesize googleThumbnails_lock = _googleThumbnails_lock;
@synthesize fetchGooglePhotosLock = _fetchGooglePhotosLock;
@synthesize isDisplay = _isDisplay;
@synthesize currentBlock = _currentBlock;
@synthesize tappedPhotoId = _tappedPhotoId;
@synthesize dropboxThumbnails = _dropboxThumbnails;
@synthesize photoDisplay = _photoDisplay;
@synthesize dropboxFetchCount = _dropboxFetchCount;
@synthesize dropboxFetchEndCount = _dropboxFetchEndCount;
@synthesize dropboxThumbnailDestAndIndex = _dropboxThumbnailDestAndIndex;
@synthesize mediaType = _mediaType;
@synthesize dropboxErrorCountPerblock = _dropboxErrorCountPerblock;
@synthesize isThumbnailViews = _isThumbnailViews;
@synthesize viewFormatButton = _viewFormatButton;
@synthesize tableView = _tableView;
@synthesize googleCurrentList = _googleCurrentList;
@synthesize dropboxCurrentList = _dropboxCurrentList;
@synthesize isDropboxRoot = _isDropboxRoot;
@synthesize refreshControl;
@synthesize delegate;
@synthesize downloadAlert = _downloadAlert;
@synthesize googleAlbumsCount = _googleAlbumsCount;
@synthesize googleAlbumsSum = _googleAlbumsSum;

- (DBRestClient *)dropClient {
    if (!_dropClient) {
        if (![DBSession sharedSession]) {
            return nil;
        }
        _dropClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dropClient.delegate = self;
    }
    return _dropClient;
}

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
    _documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _photoThumbnails = 0;
    _photoPerBlock = 12;
    _photoCount = 0;
    _columns = 3;
    _googlePhotosCount = 0;
    _imageViews = [[NSMutableArray alloc]init];
    _google_photos_lock = [[NSLock alloc]init];
    _googleThumbnails_lock = [[NSLock alloc]init];
    _googleFetchCount = 0;
    _googleFetchEndCount = 0;
    _photoIndexBegin = 0;
    _photoIndexEnd = 0;
    _photoThumbnails = [[NSMutableArray alloc]init];
    _googlePhotos = [[NSMutableArray alloc]init];
    _googleThumbnails = [[NSMutableDictionary alloc]init];
    _thumbnailLine = [[NSMutableArray alloc]init];
    _dropboxThumbnails = [[NSMutableDictionary alloc]init];
    _dropboxThumbnailDestAndIndex = [[NSMutableDictionary alloc]init];
    _googleCurrentList = [[NSMutableArray alloc]init];
    _dropboxCurrentList = [[NSMutableArray alloc]init];
    _imageHeight = 128;
    _isDisplay = YES;
    _currentBlock=0;
    _dropboxFetchCount = 0;
    _dropboxFetchEndCount = 0;
    _scrollView.delegate = self;
    _dropboxErrorCountPerblock = 0;
    _isThumbnailViews = YES;
    _isDropboxRoot = YES;
    imageSuffix = [[NSArray alloc]initWithObjects:@"jpg", @"jpeg", @"png", @"tiff", @"tif", @"gif", @"bmp", nil];
//    self.view = _tableView;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [UIApplication sharedApplication].statusBarStyle = UIBarStyleBlack;
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat toptoolbaHeight = self.navigationController.navigationBar.frame.size.height;
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, statusBarHeight+toptoolbaHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-statusBarHeight-self.tabBarController.tabBar.frame.size.height-toptoolbaHeight)];
//    [self.view addSubview:_tableView];
//    self.view = _tableView;
    _scrollView.frame = CGRectMake(0, statusBarHeight+toptoolbaHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-statusBarHeight-self.tabBarController.tabBar.frame.size.height-toptoolbaHeight);
    NSLog(@"%f %f",_scrollView.frame.size.height, _scrollView.frame.size.width);
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height+10)];
    //display photos in google storage.
    _googleAuth = [[GTMOAuth2Authentication alloc] init];
    _googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    [self googlePhotosService];
    NSString *username = _googleAuth.userEmail;
    if (username.length) {
        NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
                                                                 albumID:nil
                                                               albumName:nil
                                                                 photoID:nil
                                                                    kind:nil
                                                                  access:nil];
        //set time out?
        GDataServiceTicket *ticket = [_googlePhotoService fetchFeedWithURL:feedURL
                                                                  delegate:self
                                                         didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    }
    //display photos in dropbox;
    [self dropClient];
//    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *path = [NSString stringWithFormat:@"%@/dropbox",dir];
//    [_dropClient loadThumbnail:@"/Sfo/Photo Aug 25, 11 29 53 AM.jpg" ofSize:@"128x128" intoPath:path];
//    DropboxServiceClient *dropboxClient = [[DropboxServiceClient alloc]init];
//    [dropboxClient downloadDropboxThumbnail:path withCount:10];
    if ((!username.length) && (_dropClient)) {
        [_dropClient loadMetadata:@"/" withHash:nil];
    }
//    [_scrollView setContentInset:UIEdgeInsetsMake(statusBarHeight+2, 0, 0, 0)];
//    [_scrollView scrollRectToVisible:CGRectMake(0, 0, 320, 1) animated:YES];
    self.subImageTap = [[UITapGestureRecognizer alloc]
                        initWithTarget:self action:@selector(handleTap:)];
    [_scrollView addGestureRecognizer:self.subImageTap];
    [self addRightButtons];
     self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:self.refreshControl];

    
}

-(void)handleRefresh
{
    [self.refreshControl beginRefreshing];
    [_tableView reloadData];
    [self.refreshControl endRefreshing];
}

-(void)addRightButtons
{
    UIImage *listImage = [UIImage imageNamed:@"list.png"];
    _viewFormatButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [_viewFormatButton setBackgroundImage:listImage forState:UIControlStateNormal];
    [_viewFormatButton addTarget:self action:@selector(changeDisplayMode) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *viewFormatItem = [[UIBarButtonItem alloc] initWithCustomView:_viewFormatButton];
    //add space between fav button and location button
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width = 15;
    NSArray *barButtonItems = [NSArray arrayWithObjects:viewFormatItem, nil];
    self.navigationItem.rightBarButtonItems = barButtonItems;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
//    NSInteger sectionCount = 0;
//    if (_googlePhotos) {
//        sectionCount++;
//    }
//    if (_photoThumbnails) {
//        sectionCount++;
//    }
//    return sectionCount;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    switch (section) {
        case 0: return [_googleCurrentList count];
        case 1: return [_dropboxCurrentList count];
        default: return 1;
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section) {
        case 0:
            if ([_googleCurrentList count]!=0) {
                sectionName = @"google drive";
            }
            break;
        case 1:
            if ([_dropboxCurrentList count]!=0) {
                sectionName = @"dropbox";
            }
        default:
            break;
    }
    
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (indexPath.section == 0) {
        GDataEntryPhoto *photo = [_googleCurrentList objectAtIndex:indexPath.row];
        cell.textLabel.text = [[[photo mediaGroup]mediaTitle]stringValue];
    }
    if (indexPath.section == 1) {
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
    
    if(indexPath.section == 0){
        ShowFolderInfoViewController *listVC = [[ShowFolderInfoViewController alloc]init];
        listVC.mediaType = 0;
        listVC.folderInfo = [_googleCurrentList objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:listVC animated:YES];
    }
    if(indexPath.section == 1){
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
            [self.navigationController pushViewController:photoFullScreenVC animated:NO];
        }
    }
}


-(void)changeDisplayMode
{
    if (_isThumbnailViews) {
        UIImage *listImage = [UIImage imageNamed:@"grid.png"];;
        [_viewFormatButton setBackgroundImage:listImage forState:UIControlStateNormal];
        _isThumbnailViews = NO;
        _scrollView.hidden = YES;
        _tableView.hidden = NO;
        self.view = _tableView;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }else{
        UIImage *listImage = [UIImage imageNamed:@"list.png"];;
        [_viewFormatButton setBackgroundImage:listImage forState:UIControlStateNormal];
        _isThumbnailViews = YES;
        _scrollView.hidden = NO;
        _tableView.hidden = YES;
        self.view = _scrollView;
        [_tableView reloadData];
    }
}
// album list fetch callback
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error {
    if (error == nil) {
        // load the Change Album pop-up button with the
        // album entries
        _downloadAlert = [[UIAlertView alloc] initWithTitle:@"Download..."
                                                    message:@"\n"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.center = CGPointMake(139.5, 75.5); // .5 so it doesn't blur
        [_downloadAlert addSubview:spinner];
        [spinner startAnimating];
        [_downloadAlert show];
        NSArray *albums = [feed entries];
        _googleCurrentList = albums;
        _googleAlbumsSum = [albums count];
        if ([_googleThumbnails_lock tryLock]){
            for (int i = 0; i< [albums count]; i++){
                GDataEntryPhotoAlbum* album = [albums objectAtIndex:i];
                _googleFetchCount+=  [[album photosUsed]intValue];
                NSURL *feedURL = [[album feedLink] URL];
                //            NSLog(@"%@, %@",feedURL, album.photosUsed);
                if (feedURL) {
                    //                GDataServiceGooglePhotos *service = [self googlePhotosService];
                    GDataServiceTicket *ticket;
                    ticket = [_googlePhotoService fetchFeedWithURL:feedURL
                                                          delegate:self
                                                 didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
                }
            }
            [_googleThumbnails_lock unlock];
            if (_googleFetchCount == 0) {
                [self downloadDropboxThumbnails];
            }
        }
    }else{
        NSLog(@"couldn't get album");
        //tell user to fresh again!
    }
}

// photo list fetch callback
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    if (error) {
        NSLog(@"couldn't get photos");
        return;
    }
//    NSLog(@"%@, %@, %d", [feed access], feed.title.stringValue, feed.entries.count);
    _googleAlbumsCount++;
    NSArray *photos = [feed entries];
    [_google_photos_lock tryLock];
    for (int i = 0; i< [photos count]; i++){
        GDataEntryPhoto *photo = [photos objectAtIndex:i];
        [_googlePhotos addObject:photo];
        if (_googlePhotosCount<_photoPerBlock) {
            NSArray *thumbnails = [[photo mediaGroup]mediaThumbnails];
            if ([thumbnails count] > 2){
                NSString *imageURLString = [[thumbnails objectAtIndex:2] URLString];
                GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:imageURLString];
                [fetcher setUserData:[NSNumber numberWithInt:_googlePhotosCount]];
                [fetcher beginFetchWithDelegate:self
                              didFinishSelector:@selector(imageFetcher:finishedWithData:error:)];
            }
        }
        _googlePhotosCount++;
    }
//    _googlePhotosCount += [photos count];
    [_google_photos_lock unlock];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSMutableArray *photosWithoutSort = [[NSMutableArray alloc]init];
        int i = 0;
        for (DBMetadata *file in metadata.contents) {
            NSString* fileSuffix = [[file.filename componentsSeparatedByString:@"."] lastObject];
            if (![fileSuffix isEqual:@"rtf"] && ![fileSuffix isEqual:@"pdf"]) {
                [photosWithoutSort addObject:[metadata.contents objectAtIndex:i]];
                i++;
            }
        }
        if (_isDropboxRoot) {
            _dropboxCurrentList = photosWithoutSort;
        }
        _isDropboxRoot = NO;
        NSArray* photos = [photosWithoutSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(DBMetadata*)a lastModifiedDate];
            NSDate *second = [(DBMetadata*)b lastModifiedDate];
            return [second compare:first];
        }];
        for (DBMetadata *photoInfo in photos) {
            if (photoInfo.isDirectory == YES) {
                NSString *path = [NSString stringWithFormat: @"%@",photoInfo.path];
                [_dropClient loadMetadata: path withHash:nil];

            }else{
                [_photoThumbnails addObject:photoInfo];
                if (_photoCount <_photoPerBlock) {
                    [self displayDropboxThumbnail:_photoCount];
                }
                _photoCount++;
            }
        }
        _dropboxFetchCount = MIN(_photoPerBlock, [_photoThumbnails count]);
    }
}

-(void)displayDropboxThumbnail:(int) dropboxIndex
{
//    [_dropboxThumbnails removeAllObjects];
    DBMetadata *photoInfo = [_photoThumbnails objectAtIndex:dropboxIndex];
    NSString* downloadPath = [NSString stringWithFormat:@"%@/%@",_documentDir, photoInfo.filename];
    //check whether imageData in Local Document dir;
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:downloadPath];
    if (imageData) {
        NSDictionary *dropboxThumbnails = [[NSDictionary alloc]initWithObjectsAndKeys:imageData,[NSNumber numberWithInt:dropboxIndex+[_googlePhotos count]], nil];
        [self displayThumbnailPage:dropboxThumbnails begin:dropboxIndex+[_googlePhotos count] end:dropboxIndex+1+[_googlePhotos count]];
    }else{
        [_dropClient loadThumbnail:photoInfo.path ofSize:@"256x256" intoPath:downloadPath];
    //add to view
//    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:downloadPath];
        [_dropboxThumbnailDestAndIndex setValue:[NSNumber numberWithInt:dropboxIndex+[_googlePhotos count]] forKey:downloadPath];
//    [self displayThumbnailPage:_dropboxThumbnails begin:dropboxIndex+[_googlePhotos count] end:dropboxIndex+1+[_googlePhotos count]];
    }
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata
{
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:destPath];
    [_dropboxThumbnails setValue:imageData forKey:[_dropboxThumbnailDestAndIndex objectForKey:destPath]];
    _dropboxFetchEndCount++;
    if ((_dropboxFetchEndCount+_dropboxErrorCountPerblock == _dropboxFetchCount) && (_dropboxFetchCount!=0)) {
        NSDictionary *subDropboxThumbnails = [[NSDictionary alloc]initWithDictionary:_dropboxThumbnails copyItems:YES];
        [_dropboxThumbnails removeAllObjects];
        [self displayThumbnailPage:subDropboxThumbnails begin:_photosIndex end:_googleFetchCount+_dropboxFetchEndCount];

    }
//    [_dropboxThumbnails removeObjectForKey:[_dropboxThumbnailDestAndIndex objectForKey:destPath]];
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error
{
    NSLog(@"counld not download Dropbox Thunmbnail %@",error);
    //try again
    _dropboxErrorCountPerblock++;
}
//
-(void)downloadDropboxThumbnail:(int)page
{
//    NSRange range = NSMakeRange(page*_photoPerBlock, (page+1)*_photoPerBlock);
//    NSArray *dropboxThumbnail = [_photoThumbnails subarrayWithRange:range];
//    for (DBMetadata *photo in dropboxThumbnail) {
//        NSString* downloadPath = [NSString stringWithFormat:@"%@/%@",_documentDir, photo.filename];
//        [_dropClient loadThumbnail:photo.path ofSize:@"128x128" intoPath:downloadPath];
//        //add to view
//    }
    int photoEndIndex = MIN([_photoThumbnails count], (page+1)*_photoPerBlock);
    for (int i = page*_photoPerBlock; i<photoEndIndex; i++) {
        DBMetadata *photo = [_photoThumbnails objectAtIndex:i];
        NSString* downloadPath = [NSString stringWithFormat:@"%@/%@",_documentDir, photo.filename];
        [_dropClient loadThumbnail:photo.path ofSize:@"128x128" intoPath:downloadPath];
        //add to view
    }
}

- (void)restClient:(DBRestClient *)client
    loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
    for (NSObject *subview in [self.navigationController.navigationBar subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel*) subview;
            label.text = nil;
        }
    }
    if (self.delegate) {
        NSArray *test = [self.delegate getDeletedPhotos];
    }
}

- (GDataServiceGooglePhotos *)googlePhotosService {
    
//    static GDataServiceGooglePhotos* service = nil;
    
    if (!_googlePhotoService) {
        _googlePhotoService = [[GDataServiceGooglePhotos alloc] init];
        
        [_googlePhotoService setShouldCacheResponseData:YES];
        [_googlePhotoService setServiceShouldFollowNextLinks:YES];
    }
    [_googlePhotoService setAuthorizer:_googleAuth];
    
    return _googlePhotoService;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIImage *newImage;
    if (image.size.width/image.size.height > newSize.width/newSize.height) {
        float newWidth = newSize.width*image.size.height/newSize.height;
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake((image.size.width - newWidth)/2, 0, newWidth, image.size.height));
        newImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }else{
        float newHeight = newSize.height*image.size.width/newSize.width;
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, (image.size.height-newHeight)/2, image.size.width, newHeight));
        newImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
//    NSLog(@"%f,%f", newImage.size.width, newImage.size.height);
    return newImage;
}

- (void)displayThumbnailPage:(NSDictionary*)imagesData begin:(int) beginIndex end:(int) endIndex
{
 //   int photoCount = MIN([[self.mAlbumPhotosFeed entries] count], _photoIndexBegin+_photoPerBlock);
    //get line coordinate Y
    [_photoDisplay lock];
    int count = 0;
    int i = 0;
    while ((count<_photosIndex)&&(i<[_thumbnailLine count])) {
//        ThumbnailLineInfo *thumbnailLineInfo = ;
        ThumbnailLineInfo *imagePerLine =  [_thumbnailLine objectAtIndex:i];
        count += [imagePerLine imageCount];
        i++;
    }
    int lineIndex = i;
    if (lineIndex>0) {
        float previousLineEnd = [[_thumbnailLine objectAtIndex:(lineIndex-1)] endCoordinateX];
        int previousLineCount = [[_thumbnailLine objectAtIndex:(lineIndex-1)] imageCount];
        if (previousLineEnd < 2+(_scrollView.frame.size.width-4)/3+10) {
            if (beginIndex<endIndex) {
                NSData *imageData1 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image1 = [[UIImage alloc]initWithData:imageData1];
//                NSLog(@"image1 index %d previousLineEnd %f, height %f, width %f", beginIndex, previousLineEnd, image1.size.height, image1.size.width);
                if (image1.size.height>image1.size.width) {
                    if (beginIndex+1<endIndex) {
                        beginIndex++;
                        ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                        NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                        UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                        UIImageView *imageView1 = [[UIImageView alloc]init];
                        UIImageView *imageView2 = [[UIImageView alloc]init];
                        if (image2.size.height>image2.size.width) {
                            imageView1.frame = CGRectMake(2+(_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3 , _imageHeight);
                            imageView2.frame = CGRectMake(2+(_scrollView.frame.size.width-4)*2/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3, _imageHeight);
                            thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width-4)/3;
                            thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width-4)*2/3;
                        }else{
                            imageView1.frame = CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*4/15 , _imageHeight);
                            imageView2.frame = CGRectMake(2+(_scrollView.frame.size.width-4)*3/5, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*2/5, _imageHeight);
//                            [_scrollView addSubview:imageView2];
                            thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width-4)/3;
                            thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width-4)*3/5;
                        }
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                        image2 = [self imageWithImage:image2 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                        [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView1.layer setBorderWidth:1.0];
                        [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView2.layer setBorderWidth:1.0];
                        imageView1.image = image1;
                        imageView2.image = image2;
                        imageView1.contentMode = UIViewContentModeScaleAspectFit;
                        imageView2.contentMode = UIViewContentModeScaleAspectFit;
                        [_scrollView addSubview:imageView1];
                        [_scrollView addSubview:imageView2];
                        thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                        thumbnailInfo.imageCount = 3;
                        beginIndex++;
                        NSLog(@"_thumbnial Line 1 %d, %f, %d , %@, %@", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount, imagesData.allKeys, _googleThumbnails.allKeys);
                    }else{
                        UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3 , _imageHeight) ];
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                        [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView1.layer setBorderWidth:1.0];
                        imageView1.contentMode = UIViewContentModeScaleAspectFit;
                        imageView1.image = image1;
                        ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                        thumbnailInfo.endCoordinateX = 2+(_scrollView.frame.size.width - 4)*2/3;
                        thumbnailInfo.imageCount = 2;
                        thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width - 4)*2/3;
                        NSLog(@"_thumbnial Line 2 %d, %f, %d, %@", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount, imagesData.allKeys);
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                        [_scrollView addSubview:imageView1];
                        return;
                    }
                }else{
                    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*2/3 , _imageHeight) ];
                    image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                    [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                    [imageView1.layer setBorderWidth:1.0];
                    imageView1.contentMode = UIViewContentModeScaleAspectFit;
                    imageView1.image = image1;
                    ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                    thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                    thumbnailInfo.imageCount = 2;
                    image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                    [_scrollView addSubview:imageView1];
                    beginIndex++;
                    NSLog(@"_thumbnial Line 3 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
                }
            }else{
                return;
            }
        }else if(previousLineEnd < _scrollView.frame.size.width - 10){
            if (beginIndex<endIndex) {
                NSData *imageData1 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image1 = [[UIImage alloc]initWithData:imageData1];
                UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(previousLineEnd, _imageHeight*(lineIndex-1), _scrollView.frame.size.width-previousLineEnd, _imageHeight) ];
                image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                imageView1.image = image1;
                [_scrollView addSubview:imageView1];
                ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                thumbnailInfo.imageCount++;
                beginIndex++;
                NSLog(@"_thumbnial Line 4 %d, %f, %d, %@", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount, imagesData.allKeys);
            }else{
                return;
            }
        }
    }
 //   float coordinateY = lineIndex*_imageHeight;
//    i = beginIndex;
    
    while(beginIndex<endIndex) {
        NSData *imageData = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
//        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
//        NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails] objectAtIndex:2]);
        UIImage *image1 = [[UIImage alloc]initWithData:imageData];
        if(image1.size.height > image1.size.width){
            if (beginIndex+1<endIndex) {
                beginIndex++;
//                GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
//                NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails] objectAtIndex:2]);
                NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                if (image2.size.height>image2.size.width) {
//                    GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
 //                   NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails]objectAtIndex:2]);
                    if (beginIndex+1<endIndex) {
                        beginIndex++;
//                        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
//                        NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails] objectAtIndex:2]);
                        NSData *imageData3 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                        UIImage *image3 = [[UIImage alloc]initWithData:imageData3];
                        float imageWidth = (_scrollView.frame.size.width - 4)/3;
                        UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                        [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView1.layer setBorderWidth:1.0];
                        UIImageView *imageView2 = [[UIImageView alloc]init];
                        UIImageView *imageView3 = [[UIImageView alloc]init];
                        ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                        if (image3.size.height>image3.size.width) {
                            imageView2.frame = CGRectMake(2+imageWidth, lineIndex*_imageHeight, imageWidth, _imageHeight);
                            imageView3.frame = CGRectMake(2+imageWidth*2, lineIndex*_imageHeight, imageWidth, _imageHeight);
                            thumbnailInfo.splitCoordinate1 = 2+imageWidth;
                            thumbnailInfo.splitCoordinate2 = 2+imageWidth*2;
                        }else{
                            imageView2.frame = CGRectMake(2+(_scrollView.frame.size.width-4)/3, _imageHeight*lineIndex, (_scrollView.frame.size.width-4)*4/15 , _imageHeight);
                            imageView3.frame = CGRectMake(2+(_scrollView.frame.size.width-4)*3/5, _imageHeight*lineIndex, (_scrollView.frame.size.width-4)*2/5, _imageHeight);
                            thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width-4)/3;
                            thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width-4)*3/5;
                        }
                        [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView2.layer setBorderWidth:1.0];
                        [imageView3.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView3.layer setBorderWidth:1.0];
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                        image2 = [self imageWithImage:image2 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                        image3 = [self imageWithImage:image3 scaledToSize:CGSizeMake(imageView3.frame.size.width, imageView3.frame.size.height)];
                        imageView1.contentMode = UIViewContentModeScaleAspectFit;
                        imageView2.contentMode = UIViewContentModeScaleAspectFit;
                        imageView3.contentMode = UIViewContentModeScaleAspectFit;
                        imageView1.image = image1;
                        imageView2.image = image2;
                        imageView3.image = image3;
                        [_scrollView addSubview:imageView1];
                        [_scrollView addSubview:imageView2];
                        [_scrollView addSubview:imageView3];
                        thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                        thumbnailInfo.imageCount = 3;
                        [_thumbnailLine addObject:thumbnailInfo];
                        NSLog(@"_thumbnial Line 5 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
                        lineIndex++;
                    }else{
                        float imageWidth = (_scrollView.frame.size.width - 4)/3;
                        UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                        UIImageView *imageView2 = [[UIImageView alloc]initWithFrame:CGRectMake(2+imageWidth, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageWidth, _imageHeight)];
                        image2 = [self imageWithImage:image2 scaledToSize:CGSizeMake(imageWidth, _imageHeight)];
                        imageView1.contentMode = UIViewContentModeScaleAspectFit;
                        imageView2.contentMode = UIViewContentModeScaleAspectFit;
                        [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView1.layer setBorderWidth:1.0];
                        [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                        [imageView2.layer setBorderWidth:1.0];
                        imageView1.image = image1;
                        imageView2.image = image2;
 //                       _thumbnailLine[lineIndex] = [NSNumber numberWithInt:2];
                        ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                        thumbnailInfo.endCoordinateX = 2+imageWidth*2;
                        thumbnailInfo.imageCount = 2;
                        thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width - 4)/3;
                        thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width - 4)/3*2;
                        [_thumbnailLine addObject:thumbnailInfo];
                        NSLog(@"_thumbnial Line 6 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
                        [_scrollView addSubview:imageView1];
                        [_scrollView addSubview:imageView2];
                        lineIndex++;
                    }
                }else{
                    float imageWidth = (_scrollView.frame.size.width - 4)/3;
                    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                    image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageWidth, _imageHeight)];
                    [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                    [imageView1.layer setBorderWidth:1.0];
                    [imageView1 setContentMode:UIViewContentModeScaleAspectFit];
                    UIImageView *imageView2 = [[UIImageView alloc]initWithFrame:CGRectMake(2+imageWidth, lineIndex*_imageHeight, imageWidth*2, _imageHeight)];
                    image2 = [self imageWithImage:image2 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                    [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                    [imageView2.layer setBorderWidth:1.0];
                    [imageView2 setContentMode:UIViewContentModeScaleAspectFit];
                    imageView1.image = image1;
                    imageView2.image = image2;
                    [_scrollView addSubview:imageView1];
                    [_scrollView addSubview:imageView2];
                    ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                    thumbnailInfo.endCoordinateX = _scrollView.frame.size.width-2;
                    thumbnailInfo.imageCount = 2;
                    thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width - 4)/3;
                    [_thumbnailLine addObject: thumbnailInfo];
                    NSLog(@"_thumbnial Line 7 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
                    lineIndex++;
                }
            }else{
                float imageWidth = (_scrollView.frame.size.width - 4)/3;
                UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                [imageView1.layer setBorderWidth:1.0];
                imageView1.contentMode = UIViewContentModeScaleAspectFit;
 //               [imageView1 setContentMode:UIViewContentModeScaleAspectFill];
//                ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex)];
                imageView1.image = image1;
                [_scrollView addSubview:imageView1];
                ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                thumbnailInfo.endCoordinateX = 2+imageWidth;
                thumbnailInfo.imageCount = 1;
                thumbnailInfo.splitCoordinate1=2+(_scrollView.frame.size.width - 4)/3;
                [_thumbnailLine addObject:thumbnailInfo];
                NSLog(@"_thumbnial Line 8 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
            }

        }else{
            if (beginIndex+1<endIndex) {
                beginIndex++;
//                GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
                NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                UIImageView *imageView1 = [[UIImageView alloc]init];
                UIImageView *imageView2 = [[UIImageView alloc]init];
                ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                if (image2.size.height>image2.size.width) {
                    float imageWidth = (_scrollView.frame.size.width - 4)/3;
                    imageView1.frame = CGRectMake(2, lineIndex*_imageHeight, imageWidth*2, _imageHeight);
                    imageView2.frame = CGRectMake(2+imageWidth*2, lineIndex*_imageHeight, imageWidth, _imageHeight);
                    thumbnailInfo.splitCoordinate1 = imageWidth*2;
                }else{
                    float imageWidth = (_scrollView.frame.size.width - 4)/2;
                    imageView1.frame = CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight);
                    imageView2.frame = CGRectMake(2+imageWidth, lineIndex*_imageHeight, imageWidth, _imageHeight);
                    thumbnailInfo.splitCoordinate1 = imageWidth;
                }
                [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                [imageView1.layer setBorderWidth:1.0];
                [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                [imageView2.layer setBorderWidth:1.0];
                image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                image2 = [self imageWithImage:image2 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                [imageView1 setContentMode:UIViewContentModeScaleAspectFit];
                [imageView2 setContentMode:UIViewContentModeScaleAspectFit];
                imageView1.image = image1;
                imageView2.image = image2;
                [_scrollView addSubview:imageView1];
                [_scrollView addSubview:imageView2];          
                thumbnailInfo.endCoordinateX = _scrollView.frame.size.width-2;
                thumbnailInfo.imageCount = 2;
                [_thumbnailLine addObject:thumbnailInfo];
                NSLog(@"_thumbnial Line 9 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);
                lineIndex++;
            }else{
                float imageWidth = (_scrollView.frame.size.width - 4)/2;
                UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2, lineIndex*_imageHeight, imageWidth, _imageHeight)];
                image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                [imageView1 setContentMode:UIViewContentModeScaleAspectFit];
                imageView1.image = image1;
                [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                [imageView1.layer setBorderWidth:1.0];
                [_scrollView addSubview:imageView1];
                ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                thumbnailInfo.endCoordinateX = 2+imageWidth;
                thumbnailInfo.imageCount = 1;
                thumbnailInfo.splitCoordinate1 = imageWidth;
                [_thumbnailLine addObject:thumbnailInfo];
                NSLog(@"_thumbnial Line 10 %d, %f, %d", [_thumbnailLine count], thumbnailInfo.endCoordinateX, thumbnailInfo.imageCount);

            }
        }
        if (beginIndex+1<endIndex) {
            beginIndex++;
        }else{
            break;
        }
    }
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _imageHeight*lineIndex)];
    _photosIndex = endIndex;
    [_photoDisplay unlock];
    if ((_photosIndex >= _googleFetchCount)&&([_photoThumbnails count]==0)){
        [self downloadDropboxThumbnails];
    }
}

- (void)imageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
//        NSNumber *index = [fetcher userData];
        [_googleThumbnails setValue:data forKey:[fetcher userData]];
        _googleFetchEndCount++;
        if ((_googleFetchEndCount == _googleFetchCount)||(_googleFetchEndCount == _photoPerBlock)) {
            NSDictionary *subGoogleThumbnails = [[NSDictionary alloc]initWithDictionary:_googleThumbnails copyItems:YES];
            for (int i = 0; i<_googleFetchEndCount; i++) {
                [_googleThumbnails removeObjectForKey:[NSNumber numberWithInt:i]];
            }
            [self displayThumbnailPage:subGoogleThumbnails begin:0 end:_googleFetchEndCount];

//            [_googleThumbnails removeAllObjects];
        }
    } else {
        NSLog(@"imageFetcher:%@ error:%@", fetcher,  error);
    }
}

-(void) downloadDropboxThumbnails
{
    if (_dropClient) {
        [_dropClient loadMetadata:@"/" withHash:nil];
    }
}

- (void)scrollImageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
        [_googleThumbnails setValue:data forKey:[fetcher userData]];
        _googleFetchEndCount++;
        if ((_googleFetchEndCount == _googleFetchCount)||(_googleFetchEndCount == _photoPerBlock+_photosIndex)) {
            NSDictionary *subGoogleThumbnails = [[NSDictionary alloc]initWithDictionary:_googleThumbnails copyItems:YES];

            [self displayThumbnailPage:subGoogleThumbnails begin:_photosIndex end:_googleFetchEndCount];
//            [_googleThumbnails removeAllObjects];
            for (int i = _photosIndex; i<_googleFetchEndCount; i++) {
                [_googleThumbnails removeObjectForKey:[NSNumber numberWithInt:i]];
            }
            _isDisplay = YES;
        }
    } else {
        NSLog(@"imageFetcher:%@ error:%@", fetcher,  error);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollBeginOffset = _scrollView.contentOffset.x;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //clean all old photos and template data in memory.
//    _googleAuth = [[GTMOAuth2Authentication alloc] init];
//    _googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
//    [self googlePhotosService];
//    NSString *username = _googleAuth.userEmail;
//    if (username.length) {
//        NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
//                                                                 albumID:nil
//                                                               albumName:nil
//                                                                 photoID:nil
//                                                                    kind:nil
//                                                                  access:nil];
//        
//        GDataServiceTicket *ticket = [_googlePhotoService fetchFeedWithURL:feedURL
//                                                                  delegate:self
//                                                         didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
//    }
//    if (_scrollBeginOffset > _scrollView.contentOffset.y) {
//        if (_dropClient) {
//            [_dropClient loadMetadata:@"/" withHash:nil];
//        }
//    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ((_scrollBeginOffset < _scrollView.contentOffset.y)&&(_scrollView.contentOffset.y != 0.0) && (_scrollView.contentOffset.y != -0.0)){
        NSLog(@"scroll %f, %f", _scrollView.contentOffset.y, _scrollView.frame.size.height);
//        if ((_scrollView.contentOffset.y/_scrollView.frame.size.height>=_currentBlock)) {
//            _currentBlock = _scrollView.contentOffset.y/_scrollView.frame.size.height;
            NSLog(@"%f, %d", _scrollView.contentOffset.y/_scrollView.frame.size.height, _currentBlock);
            _currentBlock++;
            _dropboxErrorCountPerblock = 0;
            if (_photosIndex<_googleFetchCount) {
                int endIndex = MIN(_photoPerBlock+_photosIndex, _googleFetchCount);
                [_fetchGooglePhotosLock lock];
                if (!_isDisplay) {
                    [_fetchGooglePhotosLock wait];
                }
                [_fetchGooglePhotosLock unlock];
                _isDisplay = NO;
                if ([_googleThumbnails_lock tryLock]) {
//                    [_googleThumbnails removeAllObjects];
                    _googleFetchEndCount = _photosIndex;
                    for (int i = _photosIndex; i<endIndex; i++) {
//                        NSLog(@"thumbnail index %d, thumbnails array acount %d", i,[_googleThumbnails count]);
                        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:i];
                        NSArray *thumbnails = [[photo mediaGroup]mediaThumbnails];
                        if ([thumbnails count] > 2){
                            NSString *imageURLString = [[thumbnails objectAtIndex:2] URLString];
                            GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:imageURLString];
                            [fetcher setUserData:[NSNumber numberWithInt:i]];
                            [fetcher beginFetchWithDelegate:self
                                          didFinishSelector:@selector(scrollImageFetcher:finishedWithData:error:)];
                        }
                    }
                    [_googleThumbnails_lock unlock];
                }
            }
            else if(_photosIndex<_googleFetchCount+[_photoThumbnails count]){
                int getDropboxPhotosCount = MIN(_photosIndex+_photoPerBlock - _googleFetchCount,[_photoThumbnails count]);
                _dropboxFetchCount = getDropboxPhotosCount;
//                [_dropboxThumbnails removeAllObjects];
                for (int i = _photosIndex - _googleFetchCount; i<getDropboxPhotosCount; i++) {
                    [self displayDropboxThumbnail:i];
                }
            }
//        }
    }
}
-(void) handleTap:(UIGestureRecognizer*) gesture
{
    CGPoint touchPoint=[gesture locationInView:_scrollView];
    int column = touchPoint.y/_imageHeight;
    int photoIndex = 0;
    for (int i = 0; i<column; i++) {
        photoIndex += [[_thumbnailLine objectAtIndex:i]imageCount];
    }
    float splitCoordinate1 = [[_thumbnailLine objectAtIndex:column] splitCoordinate1];
    float splitCoordinate2 = [[_thumbnailLine objectAtIndex:column] splitCoordinate2];
    if ((splitCoordinate1>0)&&(touchPoint.x>splitCoordinate1)) {
        if ((splitCoordinate2>0)&&(touchPoint.x>splitCoordinate2)) {
            photoIndex +=2;
        }else{
            photoIndex++;
        }
    }
    NSLog(@"Line %d", column);
//    GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:photoIndex];
    _tappedPhotoId = photoIndex;
    if (photoIndex<[_googlePhotos count]) {
        _mediaType = 1;
    }else if(photoIndex<[_googlePhotos count]+[_photoThumbnails count])
    {
        _mediaType = 2;
    }

    [self performSegueWithIdentifier:@"ActPhotoFullScreen" sender:self];
    
    //    [UIView beginAnimations:nil context:NULL];
    //    [UIView setAnimationBeginsFromCurrentState:YES];
    //    [UIView setAnimationDuration:1.0];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    //    [UIView commitAnimations];
    //    UIImageView *imageView = [_scrollView.subviews objectAtIndex:photoIndex+2];
    //    [UIView animateWithDuration:1.0 animations:^{
    //        imageView
    //        imageView.frame = _scrollView.bounds;
    //    }];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ActPhotoFullScreen"]) {
        PhotoFullScreenViewController *fullScreenVC = segue.destinationViewController;
        if (_mediaType == 1) {
            fullScreenVC.photoIndex = _tappedPhotoId;
            fullScreenVC.googlePhotos = _googlePhotos;
            fullScreenVC.dropboxPhotos = _photoThumbnails;
        }
        if (_mediaType == 2) {
            fullScreenVC.googlePhotos = _googlePhotos;
            fullScreenVC.dropboxPhotos = _photoThumbnails;
            fullScreenVC.photoIndex = _tappedPhotoId;
        }
    }
}

@end
