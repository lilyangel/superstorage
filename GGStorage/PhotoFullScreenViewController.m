//
//  PhotoFullScreenViewController.m
//  GGStorage
//
//  Created by lily on 3/20/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "PhotoFullScreenViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"
#import <QuartzCore/CALayer.h>
#import <DropboxSDK/DropboxSDK.h>
#import "social/Social.h"
#import "accounts/Accounts.h"
#import "GData.h"
#import "GDataServiceGoogle.h"
#import "GlobalSetting.h"
#import "GDataEntryPhoto.h"
#import "RootFoldersViewController.h"
//#import "SettingViewController.h"

@interface PhotoFullScreenViewController ()<DBRestClientDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableDictionary *imageSet;
@property (nonatomic) NSMutableData *receivedData;
@property (nonatomic) NSInteger photoCount;
@property float scrollBeginOffset;
@property (nonatomic) NSInteger beginPhotoIndex;
@property (nonatomic) NSInteger endPhotoIndex;
@property Boolean isDisplayToolBar;
@property DBRestClient *dropClient;
@property NSString *documentDir;
@property UILabel *nav_title;
@property UIWebView *webView;
@property float toolbarOriginY;
@property UIImage *currentImage;
@property NSString *sharedLink;
@property GDataServiceGoogle *gdataServiceGoogle;
@property GTMOAuth2Authentication *googleAuth;
@property NSMutableArray *deletedDropboxPhotos;
@property NSMutableArray *deletedGooglePhotos;
@property UIActionSheet *fileSharedActionSheet;
@property UIActionSheet *fileDeletedActionSheet;
@property UIActionSheet *fileMovedActionSheet;
@property UITextView *fileInfoView;
@property int infoViewHeight;
@property Boolean isDisplayFileInfo;
@property NSString *fileType;
@property UIAlertView *downloadAlert;
@end

@implementation PhotoFullScreenViewController
@synthesize dropboxPhotos = _dropboxPhotos;
@synthesize googlePhotos = _googlePhotos;
@synthesize photoIndex = _photoIndex;
@synthesize connection = _connection;
@synthesize imageSet = _imageSet;
@synthesize receivedData = _receivedData;
@synthesize photoCount = _photoCount;
@synthesize scrollBeginOffset = _scrollBeginOffset;
@synthesize beginPhotoIndex = _beginPhotoIndex;
@synthesize endPhotoIndex = _endPhotoIndex;
@synthesize isDisplayToolBar = _isDisplayToolBar;
@synthesize dropClient = _dropClient;
@synthesize documentDir = _documentDir;
@synthesize nav_title = _nav_title;
@synthesize webView = _webView;
@synthesize toolBar = _toolBar;
@synthesize toolbarOriginY = _toolbarOriginY;
@synthesize currentImage = _currentImage;
@synthesize sharedLink = _sharedLink;
@synthesize gdataServiceGoogle = _gdataServiceGoogle;
@synthesize googleAuth = _googleAuth;
@synthesize deletedDropboxPhotos = _deletedDropboxPhotos;
@synthesize deletedGooglePhotos = _deletedGooglePhotos;
@synthesize fileSharedActionSheet = _fileSharedActionSheet;
@synthesize fileDeletedActionSheet = _fileDeletedActionSheet;
@synthesize fileMovedActionSheet = _fileMovedActionSheet;
@synthesize fileInfoView = _fileInfoView;
@synthesize infoViewHeight = _infoViewHeight;
@synthesize isDisplayFileInfo = _isDisplayFileInfo;
@synthesize fileType = _fileType;
@synthesize downloadAlert = _downloadAlert;

-(NSArray*)getDeletedPhotos{
    NSArray *array = [[NSArray alloc]initWithObjects:@"test", nil];
    return array;
}


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

- (UILabel*)configLabel:(UILabel*)label
{
    label.font = [UIFont fontWithName:@"Arial-BoldMT" size:18];
    label.textColor = [UIColor whiteColor];
    label.adjustsFontSizeToFitWidth = YES;
    label.backgroundColor = [UIColor clearColor];
    return label;
}

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _infoViewHeight = 200;
    [self dropClient];
    _isDisplayToolBar = NO;
    _imageSet = [[NSMutableDictionary alloc] init];
    //    if(!_scrollView)
    {
        _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        //       self.view = _scrollView;
        [self.view addSubview:_scrollView];
        [_scrollView setBounces:YES];
        _scrollView.scrollEnabled = YES;
        _scrollView.pagingEnabled = YES;
    }
    
    //Initial Toolbar attribute.
    float toolBarHeight = 44;
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] init];
    }
    _toolbarOriginY = _scrollView.frame.size.height;
    _toolBar.frame = CGRectMake(0, _toolbarOriginY, _scrollView.frame.size.width, toolBarHeight);
    _toolBar.barStyle = UIBarStyleBlack;
    [self.view addSubview:_toolBar];
    //add buttons to toolbar
    _toolBar.items = [self createButtons];
    //    _toolBar.hidden = YES;
    _documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _photoCount = [_googlePhotos count]+[_dropboxPhotos count];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    for (NSObject *subview in [self.navigationController.navigationBar subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            _nav_title = (UILabel*) subview;
        }
    }
    if (_nav_title == nil) {
        _nav_title = [[UILabel alloc] initWithFrame:CGRectMake(80, 2, 220, 25)];
        _nav_title = [self configLabel:_nav_title];
    }
    
    
    [self displayFileInfo:_photoIndex];
    [self.navigationController.navigationBar addSubview:_nav_title];
    
    self.scrollView.delegate=self;
    [_scrollView setContentSize:CGSizeMake(_scrollView.bounds.size.width * (_photoCount), _scrollView.bounds.size.height)];
    
    _beginPhotoIndex = _photoIndex;
    _endPhotoIndex = _photoIndex;
    [self imageAtIndex:_photoIndex];
    if (_photoIndex-1 >= 0) {
        [self imageAtIndex:_photoIndex-1];
        _beginPhotoIndex--;
        
    }
    if (_photoIndex+1 < _photoCount){
        [self imageAtIndex:_photoIndex+1];
        _endPhotoIndex++;
    }
    [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
    
    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(handlePhotoTap:)];
    UITapGestureRecognizer *webViewTap = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePhotoTap:)];
    webViewTap.delegate = self;
    imageTap.delegate = self;
    _scrollView.delegate = self;
    [_scrollView addGestureRecognizer:imageTap];
    _webView.delegate = self;
    _webView = [[UIWebView alloc]init];
    _webView.delegate = self;
    _webView.frame = CGRectMake(0, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
    _webView.scalesPageToFit = YES;
    
    [_webView addGestureRecognizer:webViewTap];
    
    //    [self setHidesBottomBarWhenPushed:YES];
    //    [_toolBar setHidden:NO];
    
//    NSArray *views = [self.view subviews];
//    for (UIView *view in views) {
//        NSLog(@"subview %f, %f, %f, %f", view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height );
//    }
    [self googlePhotosService];
    //    int count = [self.navigationController.viewControllers count];
    //    UIViewController *theControllerYouWant = [self.navigationController.viewControllers objectAtIndex:(count - 2)];
    //
    //    PhotoViewController *pfsVC = (PhotoViewController*)theControllerYouWant;
    //    pfsVC.delegate = self;
    _fileInfoView = [[UITextView alloc]initWithFrame:CGRectMake(0, _scrollView.frame.size.height, _scrollView.frame.size.width, _infoViewHeight)];
    //    UIImageView *imgView = [[UIImageView alloc]initWithFrame: _fileInfoView.frame];
    //    imgView.image = [UIImage imageNamed: @"download.png"];
    //    [_fileInfoView addSubview: imgView];
    //    [_fileInfoView bringSubviewToFront: imgView];
    _fileInfoView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed: @"fileInfoBg.png"]];
    _fileInfoView.editable = NO;
    [_fileInfoView setTextColor:[UIColor whiteColor]];
    [self.view addSubview:_fileInfoView];
    _isDisplayFileInfo = NO;
}

- (NSArray*)createButtons
{
    //add permission button
    UIImage *sharedImage = [UIImage imageNamed:@"person_small.png"];
    UIButton *sharedButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [sharedButton setBackgroundImage:sharedImage forState:UIControlStateNormal];
    [sharedButton addTarget:self action:@selector(clickSharedFile) forControlEvents:UIControlEventTouchUpInside];
    //add delete button
    UIImage *deleteImage = [UIImage imageNamed:@"Trash.png"];
    UIButton *deleteButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 25, 25)];
    [deleteButton setBackgroundImage:deleteImage forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(clickDeleteFile) forControlEvents:UIControlEventTouchUpInside];
    //add fie move to other folder button
    UIImage *infoImage = [UIImage imageNamed:@"info.png"];
    UIButton *infoButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 25)];
    [infoButton setBackgroundImage:infoImage forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(clickInfoFile) forControlEvents:UIControlEventTouchUpInside];
    //add other button
    UIImage *moreImage = [UIImage imageNamed:@"download.png"];
    UIButton *moreButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 25)];
    [moreButton setBackgroundImage:moreImage forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(clickDownload) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *permissionItem = [[UIBarButtonItem alloc] initWithCustomView:sharedButton];
    UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithCustomView:deleteButton];
    UIBarButtonItem *folderItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
    //add space between fav button and location button
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    spaceItem.width = (_toolBar.frame.size.width - 40*4)/3;
    NSArray *barButtonItems = [NSArray arrayWithObjects:permissionItem, spaceItem, deleteItem, spaceItem, folderItem, spaceItem, moreItem, nil];
    return barButtonItems;
}

-(void)clickDownload{
    if (_photoIndex < [_googlePhotos count]) {
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:_photoIndex];
        GDataQuery *query = [GDataQuery queryWithFeedURL:photo.content.sourceURL];
        [query addCustomParameterWithName:@"imgmax" value: [photo.height stringValue]];
        NSURL *downloadURL = [query URL];
        NSArray* mediaGroups = photo.mediaGroup.mediaContents;
        if ([mediaGroups count]>1) {
            GDataMediaContent *mediaContent = [mediaGroups objectAtIndex:1];
            if ([mediaContent.medium isEqual:@"video"]) {
                _fileType = @"video";
                //could not download video file now.
                //                NSLog(@"%@", photo.content.sourceURL);
                //                UISaveVideoAtPathToSavedPhotosAlbum([photo.content.sourceURL absoluteString], nil, nil, nil);
                return;
            }
        }
        _fileType = @"image";
        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:photo.content.sourceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
        _connection = [[NSURLConnection alloc ] initWithRequest:theRequest delegate:self];
        _receivedData = [[NSMutableData alloc ] init];
        NSMutableDictionary *downloadFullData = [[NSMutableDictionary alloc]init];
        [downloadFullData setObject:_receivedData forKey:@"fullData"];
        [_imageSet setObject:downloadFullData forKey:_connection.description];
    }else if(_photoIndex < [_googlePhotos count] + [_dropboxPhotos count]){
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:_photoIndex-[_googlePhotos count]];
        NSString* downloadPath = [NSString stringWithFormat:@"%@/fullSize_%d_%@",_documentDir,_photoIndex ,photo.filename];
        NSString* fileSuffix = [[photo.filename componentsSeparatedByString:@"."] lastObject];
        if([fileSuffix isEqual:@"jpg"]||[fileSuffix isEqual:@"jpeg"]||[fileSuffix isEqual:@"bmp"]||[fileSuffix isEqual:@"png"]||[fileSuffix isEqual:@"gif"]){
            [_dropClient loadFile:photo.path intoPath:downloadPath];
        }else{
            //could not download this file;
        }
    }
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
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath{
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:destPath];
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [_downloadAlert dismissWithClickedButtonIndex:0 animated:YES];
    [fileManager removeItemAtPath:destPath error:NULL];
}

-(void)clickMoveFile{
    
    //    if (_photoIndex < [_googlePhotos count]) {
    ////        _fileMovedActionSheet = [[UIActionSheet alloc]init];
    ////        [_fileMovedActionSheet setFrame:CGRectMake(0, 250, 320, 400)];
    //        _fileMovedActionSheet = [[UIActionSheet alloc] initWithTitle:nil
    //                                                             delegate:self
    //                                                    cancelButtonTitle:@"Cancel"
    //                                               destructiveButtonTitle:nil
    //                                                    otherButtonTitles:nil];
    //
    ////        UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 100, 320, 400) style:UITableViewStylePlain];
    //        UITableView *tableView = [[UITableView alloc]init];
    //        tableView.frame = CGRectMake(0, -300, 320, 400);
    //        GoogleFolderViewController *googleFolderVC = [[GoogleFolderViewController alloc]init];
    //        [tableView setDelegate:self];
    //        [tableView setDataSource:self];
    //        [_fileMovedActionSheet addSubview:tableView];
    //        NSLog(@"%f, %f, %f, %f", _fileMovedActionSheet.frame.origin.x, _fileMovedActionSheet.frame.origin.y, _fileMovedActionSheet.frame.size.width, _fileMovedActionSheet.frame.size.height);
    //    }
    //    _fileMovedActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    //    [_fileMovedActionSheet showInView:self.view];
    
    //    if (_photoIndex < [_googlePhotos count]) {
    ////        rootFolderVC.googleCurrentList = _googlePhotos;
    //        NSString *username = _googleAuth.userEmail;
    //        if (username.length) {
    //            NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
    //                                                                     albumID:nil
    //                                                                   albumName:nil
    //                                                                     photoID:nil
    //                                                                        kind:nil
    //                                                                      access:nil];
    //            //set time out?
    //            GDataServiceTicket *ticket = [_gdataServiceGoogle fetchFeedWithURL:feedURL
    //                                                                      delegate:self
    //                                                             didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    //        }
    //    }else if(_photoIndex < [_googlePhotos count]+[_dropboxPhotos count]){
    ////        rootFolderVC.dropboxCurrentList = _dropboxPhotos;
    //    }
    ////    [self.navigationController pushViewController:rootFolderVC animated:YES];
}

-(void)clickInfoFile
{
    NSString *fileInfoStr = [[NSString alloc]init];
    if (_photoIndex < [_googlePhotos count]) {
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:_photoIndex];
        NSArray *fileInfoTags = photo.EXIFTags.tags;
        /*
         fstop:2.4
         make:Apple
         model:iPhone 4S
         exposure:2.8901733E-4
         flash:false
         focallength:4.28
         iso:50
         time:1364042234000
         imageUniqueID:d8d4221db123a9879e532d0cd8547fe7
         */
        int lineCount = 0;
        for (GDataEXIFTag *content in fileInfoTags) {
            if ([content.name isEqualToString:@"fstop"]) {
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"F Number : %@\n",content.stringValue];
                lineCount++;
            }else if([content.name isEqualToString:@"model"]){
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Camera : %@\n",content.stringValue];
                lineCount++;
            }else if([content.name isEqualToString:@"exposure"]){
                float exposureValue = [content.stringValue floatValue];
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Exposure : %f\n",exposureValue];
                lineCount++;
            }else if([content.name isEqualToString:@"flash"]){
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"flash : %@\n",content.stringValue];
                lineCount++;
            }else if([content.name isEqualToString:@"focallength"]){
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Focal Length : %@\n",content.stringValue];
                lineCount++;
            }else if([content.name isEqualToString:@"iso"]){
                fileInfoStr = [fileInfoStr stringByAppendingFormat:@"ISO : %@\n",content.stringValue];
                lineCount++;
            }
        }
        NSDate *photoTime = [photo.timestamp dateValue];
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"PST"]];
        [dateFormat setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
        NSString* timeStr = [dateFormat stringFromDate:photoTime];
        
        fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Date taken : %@\n",timeStr];
        fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Size : %d\n",photo.size.intValue];
        _fileInfoView.text = fileInfoStr;
        CGRect fileInfoFrame = _fileInfoView.frame;
        fileInfoFrame.size.height = _fileInfoView.font.lineHeight*(lineCount+3);
        _fileInfoView.frame = fileInfoFrame;
    }else if(_photoIndex < [_googlePhotos count] + [_dropboxPhotos count]){
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:_photoIndex-[_googlePhotos count]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"PST"]];
        [dateFormat setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
        NSString* timeStr = [dateFormat stringFromDate:photo.clientMtime];
        fileInfoStr = [fileInfoStr stringByAppendingFormat:@"Size : %@\nDate taken : %@", photo.humanReadableSize, timeStr];
        CGRect fileInfoFrame = _fileInfoView.frame;
        fileInfoFrame.size.height = _fileInfoView.font.lineHeight*3;
        _fileInfoView.frame = fileInfoFrame;
        _fileInfoView.text = fileInfoStr;
    }
    if (_isDisplayFileInfo) {
        [self disappearFileInfo];
        _isDisplayFileInfo = NO;
    }else{
        [self displayFileInfo];
        _isDisplayFileInfo = YES;
    }
}

-(void)displayFileInfo
{
    [UIView beginAnimations:@"DisplayInfoView" context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:_fileInfoView cache:YES];
    CGRect fileInfoFrame = _fileInfoView.frame;
    fileInfoFrame.origin.y = _scrollView.frame.size.height - _fileInfoView.frame.size.height;
    _fileInfoView.frame = fileInfoFrame;
    [self.view bringSubviewToFront:_fileInfoView];
    [self.view bringSubviewToFront:_toolBar];
    [UIView commitAnimations];
}

-(void)disappearFileInfo
{
    [UIView beginAnimations:@"DisplayInfoView" context:nil];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:_fileInfoView cache:YES];
    CGRect fileInfoFrame = _fileInfoView.frame;
    fileInfoFrame.origin.y = [UIScreen mainScreen].bounds.size.height;
    _fileInfoView.frame = fileInfoFrame;
    [self.view bringSubviewToFront:_fileInfoView];
    [self.view bringSubviewToFront:_toolBar];
    [UIView commitAnimations];
}

//- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
//            finishedWithFeed:(GDataFeedPhotoUser *)feed
//                       error:(NSError *)error {
//    if (error == nil) {
//        // load the Change Album pop-up button with the
//        // album entries
//        NSArray *albums = [feed entries];
//        RootFoldersViewController *rootFolderVC = [[RootFoldersViewController alloc]init];
//        rootFolderVC.mediaType = _mediaType;
//        rootFolderVC.showFullPhoto = NO;
//        rootFolderVC.googleCurrentList = [albums mutableCopy];
//        rootFolderVC.currentFile = [_googlePhotos objectAtIndex:_photoIndex];
//        [self.navigationController pushViewController:rootFolderVC animated:YES];
//    }else{
//        NSLog(@"couldn't get album");
//        //tell user to fresh again!
//    }
//}

-(void)clickSharedFile
{
    //   UIActionSheet *actionSheet;
    if (_photoIndex < [_googlePhotos count]) {
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:_photoIndex];
        NSURL *datalink = [[photo alternateLink]URL];
        NSLog(@"%@", datalink);
        _sharedLink = datalink;
        _fileSharedActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Facebook", @"Twitter", @"Weibo", nil];
        _fileSharedActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        
    }else if (_photoIndex < [_googlePhotos count] + [_dropboxPhotos count]) {
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:_photoIndex-[_googlePhotos count]];
        [_dropClient loadSharableLinkForFile:photo.path];
        _fileSharedActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Facebook", @"Twitter", @"Weibo", nil];
        _fileSharedActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    }
    // open a dialog with just an OK button
    
    //        photo.
    
    [_fileSharedActionSheet showInView:self.view];
}

-(void)clickDeleteFile
{
    _fileDeletedActionSheet = [[UIActionSheet alloc] initWithTitle:@"this file will be deleted"
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Delete", nil];
    _fileDeletedActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [_fileDeletedActionSheet showInView:self.view];
}

-(void)deleteFile{
    if (_photoIndex < [_googlePhotos count]) {
        NSString *username = _googleAuth.userEmail;
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:_photoIndex];
        if (username.length) {
            GDataServiceTicket *ticket = [_gdataServiceGoogle deleteResourceURL:photo.editLink.URL
                                                                           ETag:kGDataETagWildcard
                                                                       delegate:self
                                                              didFinishSelector:@selector(deletedTicket:finishedWithFeed:error:)];
        }
    }else if(_photoIndex < [_googlePhotos count] + [_dropboxPhotos count]) {
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:_photoIndex-[_googlePhotos count]];
        [_dropClient deletePath:photo.path];
    }
}

- (void)deletedTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedPhotoAlbum *)feed
                error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
        return;
    }
    int googlePhotoIndex = _photoIndex;
    [_googlePhotos removeObjectAtIndex:googlePhotoIndex];
    NSNumber *deletedGooglePhotoIndex = [[NSNumber alloc]initWithInt: googlePhotoIndex];
    [_deletedGooglePhotos addObject:deletedGooglePhotoIndex];
    [self showNextPhoto];
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path {
    NSLog(@"delete %@", path);
    int dropboxPhotoIndex = _photoIndex - [_googlePhotos count];
    [_dropboxPhotos removeObjectAtIndex:dropboxPhotoIndex];
    NSNumber *deletedDropboxPhotoIndex = [[NSNumber alloc]initWithInt: dropboxPhotoIndex];
    [_deletedDropboxPhotos addObject:deletedDropboxPhotoIndex];
    [self showNextPhoto];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"delete photo error!"
                                                    message:nil
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path
{
    NSLog(@"%@",link);
    _sharedLink = link;
}

-(void)changeAccessInGdata
{
    NSString *username = _googleAuth.userEmail;
    GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:_photoIndex];
    //    if (username.length) {
    //        NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
    //                                                                 albumID:nil
    //                                                               albumName:nil
    //                                                                 photoID:photo.identifier
    //                                                                    kind:nil
    //                                                                  access:nil];
    //
    //        GDataServiceTicket *ticket = [_gdataServiceGoogle fetchFeedWithURL:feedURL
    //                                                                  delegate:self
    //                                                         didFinishSelector:@selector(photoTicket:finishedWithFeed:error:)];
    //    }
    NSLog(@"%@, %@", photo.rightsString, photo.title.stringValue);
    //   _gdataServiceGoogle fetchEntryByUpdatingEntry:(GDataEntryBase *) delegate:<#(id)#> didFinishSelector:<#(SEL)#>
}

//- (void)photoTicket:(GDataServiceTicket *)ticket
//    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
//               error:(NSError *)error
//{
//    GDataEntryBase *entry = [[feed entries] objectAtIndex:0];
//    [_gdataServiceGoogle fetchEntryByUpdatingEntry:<#(GDataEntryBase *)#> forEntryURL:<#(NSURL *)#> delegate:<#(id)#> didFinishSelector:<#(SEL)#>]
//}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _fileSharedActionSheet) {
        NSString *serviceType;
        if (buttonIndex == [actionSheet cancelButtonIndex]) {
            return;
        }else if (buttonIndex == 0) {
            NSLog(@"facebook");
            serviceType = SLServiceTypeFacebook;
        } else if (buttonIndex == 1) {
            NSLog(@"Twitter");
            serviceType = SLServiceTypeTwitter;
        } else if (buttonIndex == 2) {
            NSLog(@"weibo");
            serviceType = SLServiceTypeSinaWeibo;
        }
        
        if (buttonIndex == 3) {
            //share file via Google
            [self changeAccessInGdata];
            return;
        }
        if([SLComposeViewController isAvailableForServiceType:serviceType]) {
            
            SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            
            SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
                if (result == SLComposeViewControllerResultCancelled) {
                    
                    NSLog(@"Cancelled");
                    
                } else
                    
                {
                    NSLog(@"Done");
                }
                
                [controller dismissViewControllerAnimated:YES completion:Nil];
            };
            controller.completionHandler =myBlock;
            
            //Adding the Text to the facebook post value from iOS
            if (_currentImage) {
                [controller setInitialText:@"Hi, i would like to share with you about this photo"];
                
                [controller addImage:_currentImage];
            }else{
                [controller setInitialText:@"Hi, i would like to share with you about this file"];
                
                [controller addURL:[NSURL URLWithString:_sharedLink]];
            }
            
            [self presentViewController:controller animated:YES completion:Nil];
            
        }
        else{
            NSLog(@"UnAvailable");
        }
    }
    if (actionSheet == _fileDeletedActionSheet) {
        if (buttonIndex == 0) {
            [self deleteFile];
        }
    }
}

-(void)displayFileInfo:(NSInteger)photoIndex
{
    if (_photoIndex < [_googlePhotos count]) {
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:photoIndex];
        _nav_title.text = [[[photo mediaGroup] mediaTitle]stringValue];
    }else if (_photoIndex < [_googlePhotos count] + [_dropboxPhotos count]) {
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:photoIndex - [_googlePhotos count]];
        _nav_title.text = photo.filename;
    }
}

-(void)handlePhotoTap:(UITapGestureRecognizer*)gesture
{
    if(_isDisplayFileInfo){
        [self disappearFileInfo];
        _isDisplayFileInfo = NO;
    }
    if (_isDisplayToolBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        _scrollView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        NSArray *views = [_scrollView subviews];
        for (UIView *view in views) {
            if ([view isKindOfClass:[UIImageView class]] && view.frame.size.width == _scrollView.bounds.size.width) {
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            }
        }
        [UIView beginAnimations:@"hideView" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:_toolBar cache:YES];
        CGRect toolbarFrame = _toolBar.frame;
        toolbarFrame.origin.y = _scrollView.frame.size.height; // moves iPad Toolbar off screen
        _toolBar.frame = toolbarFrame;
        [UIView commitAnimations];
        //        [_toolBar setHidden:YES];
        _isDisplayToolBar = NO;
    }else{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        _scrollView.frame = CGRectMake(0,
                                       0,
                                       [UIScreen mainScreen].bounds.size.width,
                                       [UIScreen mainScreen].bounds.size.height - _toolBar.frame.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
        NSArray *views = [_scrollView subviews];
        for (UIView *view in views) {
            if ([view isKindOfClass:[UIImageView class]] && view.frame.size.width == _scrollView.bounds.size.width && view.frame.size.height > 100) {
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            }
        }
        //        [UIView animateWithDuration:.2
        //                         animations:^(void)
        //         {
        //             CGRect toolbarFrame = _toolBar.frame;
        //             toolbarFrame.origin.y = _toolbarOriginY - 100; // moves iPad Toolbar off screen
        //             _toolBar.frame = toolbarFrame;
        //         }
        //                         completion:^(BOOL finished)
        //         {
        ////             _toolBar.hidden = NO;
        //         }];
        [UIView beginAnimations:@"hideView" context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:_toolBar cache:YES];
        CGRect toolbarFrame = _toolBar.frame;
        toolbarFrame.origin.y = _scrollView.frame.size.height; // moves iPad Toolbar off screen
        _toolBar.frame = toolbarFrame;
        [UIView commitAnimations];
        //      [_toolBar setHidden:NO];0
        _isDisplayToolBar = YES;
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
    return YES;
}

- (void) imageAtIndex:(NSUInteger) photoIndex
{
    if(photoIndex>=_photoCount)
        return;
    if (photoIndex<[_googlePhotos count]) {
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:photoIndex];
        NSURL *urlString = [NSURL URLWithString:[[[[photo mediaGroup]mediaContents]objectAtIndex:0]URLString]];
        [self sendGetPhotoDataRequest:urlString withPhotoIndex:photoIndex];
    }else if (photoIndex < [_googlePhotos count]+[_dropboxPhotos count]) {
        DBMetadata *photo = [_dropboxPhotos objectAtIndex:photoIndex-[_googlePhotos count]];
        NSString* downloadPath = [NSString stringWithFormat:@"%@/%d_%@",_documentDir,photoIndex ,photo.filename];
        NSString* fileSuffix = [[photo.filename componentsSeparatedByString:@"."] lastObject];
        
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:downloadPath];
        if([fileSuffix isEqual:@"rtf"]||[fileSuffix isEqual:@"pdf"]){
            [_dropClient loadFile:photo.path intoPath:downloadPath];
        } else if (imageData) {
            [self displayImage:imageData withPageIndex:photoIndex];
        } else{
            [_dropClient loadThumbnail:photo.path ofSize:@"640x480" intoPath:downloadPath];
        }
    }
    return;
}


- (void)sendGetPhotoDataRequest:(NSURL*)urlString withPhotoIndex:(int)photoIndex
{
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:urlString cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    _connection = [[NSURLConnection alloc ] initWithRequest:theRequest delegate:self];
    
    _receivedData = [[NSMutableData alloc ] init];
    
    NSMutableDictionary *dataAndPhotoIndex = [[NSMutableDictionary alloc] init];
    [dataAndPhotoIndex setObject:_receivedData forKey:[NSString stringWithFormat:@"%d", photoIndex]];
    NSMutableDictionary *imageAndURL = [[NSMutableDictionary alloc] init];
    [imageAndURL setObject:dataAndPhotoIndex forKey:urlString];
    [_imageSet setObject:imageAndURL forKey:_connection.description];
    dataAndPhotoIndex = nil;
    imageAndURL = nil;
    
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSMutableDictionary *imageAndURL = [_imageSet objectForKey:connection.description];
    if ([[[imageAndURL allKeys]objectAtIndex:0] isEqual:@"fullData"]) {
        NSMutableData *theReceived = [[imageAndURL allValues]objectAtIndex:0];
        [theReceived setLength:0];
        return;
    }
    NSMutableData *theReceived = [[[imageAndURL objectForKey:response.URL] allValues]objectAtIndex:0];
    [theReceived setLength:0];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableDictionary *imageAndURL = [_imageSet objectForKey:connection.description];
    if ([[[imageAndURL allKeys]objectAtIndex:0] isEqual:@"fullData"]) {
        NSMutableData *theReceived = [[imageAndURL allValues]objectAtIndex:0];
        [theReceived appendData:data];
        return;
    }
    NSMutableData *theReceived = [[[[imageAndURL allValues] objectAtIndex:0] allValues]objectAtIndex:0];
    [theReceived appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSMutableData *theReceived;
    if ([[[[_imageSet objectForKey:connection.description] allKeys]objectAtIndex:0] isEqual:@"fullData"]) {
        theReceived = [[[_imageSet objectForKey:connection.description] allValues]objectAtIndex:0];
    }else{
        theReceived = [[[[[_imageSet objectForKey:[connection description]]allValues]objectAtIndex:0]allValues]objectAtIndex:0];
    }
    theReceived = nil;
    connection = nil;
    NSLog(@"connection failed,ERROR %@", [error localizedDescription]);
    [[[UIAlertView alloc]
      initWithTitle:@"Downloading Error" message:nil
      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
     show];
}

- (void)image: (UIImage *)image didFinishSavingWithError: (NSError *)error contextInfo: (void *)contextInfo{
    if (error != nil) {
        
    }
    [_downloadAlert dismissWithClickedButtonIndex:0 animated:YES];
    
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSMutableDictionary *imageAndURL = [_imageSet objectForKey:connection.description];
    if (imageAndURL == nil) {
        return;
    }
    if ([[[imageAndURL allKeys]objectAtIndex:0] isEqual:@"fullData"]) {
        NSMutableData *theReceived = [[imageAndURL allValues]objectAtIndex:0];
        [_imageSet removeObjectForKey:connection.description];
        //this image data is full size google nsdata, need to store to
        UIImage *googleImage = [[UIImage alloc]initWithData:theReceived];
        if ([_fileType isEqual:@"image"]) {
            UIImageWriteToSavedPhotosAlbum(googleImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }else if ([_fileType isEqual:@"video"]){
            
        }
        [self setConnection: nil];
        [self setReceivedData:nil];
        return;
    }
    NSMutableData *theReceived = [[[[imageAndURL allValues] objectAtIndex:0] allValues]objectAtIndex:0];
    
    if (theReceived == nil) {
        NSLog(@"No image data");
    }
    
    int photoIndex = [[[[[imageAndURL allValues] objectAtIndex:0] allKeys]objectAtIndex:0] intValue];
    [self displayImage:theReceived withPageIndex:photoIndex];
    
    //store to local
    [_imageSet removeObjectForKey:connection.description];
    [self setConnection: nil];
    [self setReceivedData:nil];
    
}

- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata
{
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:destPath];
    NSString *documentDir = [NSString stringWithFormat:@"%@/", _documentDir];
    NSString *loadFilename = [[destPath componentsSeparatedByString:documentDir]objectAtIndex:1];
    NSInteger photoIndex = [[[loadFilename componentsSeparatedByString:@"_"] objectAtIndex:0]integerValue];
    [self displayImage:imageData withPageIndex:photoIndex];
}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error
{
    NSLog(@"counld not download Dropbox Thunmbnail %@",error);
    //try again
    //download origional file;
    NSString *path = [error.userInfo valueForKey:@"path"];
    NSString *localDestination = [error.userInfo valueForKey:@"destinationPath"];
    [_dropClient loadFile:path intoPath:localDestination];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath contentType:(NSString *)contentType metadata:(DBMetadata *)metadata{
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:destPath];
    NSString *documentDir = [NSString stringWithFormat:@"%@/", _documentDir];
    NSString *loadFilename = [[destPath componentsSeparatedByString:documentDir]objectAtIndex:1];
    NSInteger photoIndex = [[[loadFilename componentsSeparatedByString:@"_"] objectAtIndex:0]integerValue];
    UIImage *image = [UIImage imageWithData:imageData];
    if (image == nil) {
        
        //NSString* htmlString = [NSString stringWithContentsOfFile:destPath encoding:NSUTF8StringEncoding error:nil];
        //htmlString = [NSString stringWithFormat:@"<html>" "<body>" "<p>%@</p>" "</body></html>", htmlString];
        //[webView loadHTMLString:htmlString baseURL:nil];
        NSURLRequest *request = [NSURLRequest requestWithURL:[[NSURL alloc] initFileURLWithPath:destPath]];
        [_webView loadRequest: request];
        
        //        self.view = _webView;
        [_scrollView removeFromSuperview];
        [self.view addSubview:_webView];
        //[_scrollView addSubview:webView];
        return;
    }
    [self displayImage:imageData withPageIndex:photoIndex];
    
}


/*
 - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
 {
 return YES;
 }
 
 - (void)webViewDidStartLoad:(UIWebView *)webView
 {
 NSLog(@"loading page");
 }
 */

- (void) displayImage:(NSData *)imageData withPageIndex:(NSInteger)pageIndex
{
    //    self.view = _scrollView;
    [_webView removeFromSuperview];
    [self.view addSubview:_scrollView];
    if (imageData == nil) {
        return;
    }
    UIImage *image = [UIImage imageWithData:imageData];
    _currentImage = image;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(_scrollView.bounds.size.width*pageIndex, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
    [imageView.layer setBorderWidth:5.0];
    [imageView.layer setBorderColor:[[UIColor blackColor] CGColor]];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [_scrollView addSubview:imageView];
    imageView = nil;
    image = nil;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollBeginOffset = scrollView.contentOffset.x;
}

-(void)showNextPhoto
{
    _photoIndex++;
    [self displayFileInfo:_photoIndex];
    [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
    if ((_endPhotoIndex +1 < _photoCount) &&(_endPhotoIndex == _photoIndex)) {
        _endPhotoIndex++;
        [self imageAtIndex:_endPhotoIndex];
        if (_photoIndex - _beginPhotoIndex >= 2) {
            for (UIImageView *imageView in [_scrollView subviews]) {
                float distance = imageView.frame.origin.x-5 - _scrollView.bounds.size.width * _beginPhotoIndex;
                if ((distance<(float)10.0) && (distance > (float)(-10.0))) {
                    [imageView removeFromSuperview];
                    imageView.image = nil;
                    _beginPhotoIndex++;
                    break;
                }
            }
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ((_scrollBeginOffset < _scrollView.contentOffset.x)&&(_scrollView.contentOffset.x != 0.0) && (_scrollView.contentOffset.x != -0.0)&&(_photoIndex<_photoCount-1)) {
        //        _photoIndex++;
        //        [self displayTitle:_photoIndex];
        //        [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
        //        if ((_endPhotoIndex +1 < _photoCount) &&(_endPhotoIndex == _photoIndex)) {
        //            _endPhotoIndex++;
        //            [self imageAtIndex:_endPhotoIndex];
        //            if (_photoIndex - _beginPhotoIndex >= 2) {
        //                for (UIImageView *imageView in [_scrollView subviews]) {
        //                    float distance = imageView.frame.origin.x-5 - _scrollView.bounds.size.width * _beginPhotoIndex;
        //                    if ((distance<(float)10.0) && (distance > (float)(-10.0))) {
        //                        [imageView removeFromSuperview];
        //                        imageView.image = nil;
        //                        _beginPhotoIndex++;
        //                        break;
        //                    }
        //                }
        //            }
        //        }
        [self showNextPhoto];
    }else if((_scrollBeginOffset > _scrollView.contentOffset.x)&&(_photoIndex>0)){
        _photoIndex--;
        [self displayFileInfo:_photoIndex];
        [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
        if ((_beginPhotoIndex - 1 >= 0)&&(_beginPhotoIndex == _photoIndex)) {
            _beginPhotoIndex--;
            [self imageAtIndex:_beginPhotoIndex];
            if (_endPhotoIndex - _photoIndex >= 2) {
                for (UIImageView *imageView in [_scrollView subviews]) {
                    float distance = imageView.frame.origin.x-5 - _scrollView.bounds.size.width * _endPhotoIndex;
                    if ((distance<(float)10.0) && (distance > (float)(-10.0))) {
                        [imageView removeFromSuperview];
                        imageView.image = nil;
                        _endPhotoIndex--;
                        break;
                    }
                }
            }
        }
    }else{
        return;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_isDisplayToolBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        _scrollView.frame = CGRectMake(0,
                                       0,
                                       [UIScreen mainScreen].bounds.size.width,
                                       [UIScreen mainScreen].bounds.size.height - _toolBar.frame.size.height - self.navigationController.navigationBar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
        NSArray *views = [_scrollView subviews];
        for (UIView *view in views) {
            if ([view isKindOfClass:[UIImageView class]] && view.frame.size.width == _scrollView.bounds.size.width && view.frame.size.height > 100) {
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            }
        }
        CGRect toolbarFrame = _toolBar.frame;
        toolbarFrame.origin.y = _scrollView.frame.size.height; // moves iPad Toolbar off screen
        _toolBar.frame = toolbarFrame;
    }else{
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        _scrollView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        NSArray *views = [_scrollView subviews];
        for (UIView *view in views) {
            if ([view isKindOfClass:[UIImageView class]] && view.frame.size.width == _scrollView.bounds.size.width && view.frame.size.height > 100) {
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
            }
        }
        CGRect toolbarFrame = _toolBar.frame;
        toolbarFrame.origin.y = _scrollView.frame.size.height; // moves iPad Toolbar off screen
        _toolBar.frame = toolbarFrame;
        //        [_toolBar setHidden:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = @"test";
    return cell;
}

@end
