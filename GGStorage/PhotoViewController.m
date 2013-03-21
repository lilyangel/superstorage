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
#import "PhotoFullScreenViewController.h"
//#import "DropboxServiceClient.h"

@interface PhotoViewController ()<DBRestClientDelegate>
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
@property int googleFetchCount;
@property int googleFetchEndCount;
@property GDataServiceGooglePhotos *googlePhotoService;
@property float scrollBeginOffset;
@property float scrollEndOffset;
@property int googlePhotosIndex;
@property NSCondition *fetchGooglePhotosLock;
@property Boolean isDisplay;
@property int currentBlock;
@property (nonatomic, strong) UITapGestureRecognizer *subImageTap;
@property int tappedPhotoId;
@end

//NSString * const kGTMOAuth2AccountName = @"OAuth";
//static NSString *const kKeychainItemName = @"Google Drive Quickstart";
//static NSString *const kClientID = @"81720981197.apps.googleusercontent.com";
//static NSString *const kClientSecret = @"EjZNvAXWx7D79EnvyHOpiw4W";

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
@synthesize googlePhotosIndex = _googlePhotosIndex;
@synthesize googleThumbnails_lock = _googleThumbnails_lock;
@synthesize fetchGooglePhotosLock = _fetchGooglePhotosLock;
@synthesize isDisplay = _isDisplay;
@synthesize currentBlock = _currentBlock;
@synthesize tappedPhotoId = _tappedPhotoId;

- (DBRestClient *)dropClient {
    if (!_dropClient) {
        _dropClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
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
    //    _dropboxThumbnailPage = 0;
//    _googleThumbnailIndex = 0;
    _photoIndexBegin = 0;
    _photoIndexEnd = 0;
    _photoThumbnails = [[NSMutableArray alloc]init];
    _googlePhotos = [[NSMutableArray alloc]init];
    _googleThumbnails = [[NSMutableDictionary alloc]init];
    _thumbnailLine = [[NSMutableArray alloc]init];
//    _imageWidth = (_scrollView.frame.size.width-4)/_columns;
    _imageHeight = 128;
    _isDisplay = YES;
    _currentBlock=0;
    _scrollView.delegate = self;
  //  NSLog(@"%f %f",_scrollView.frame.size.height, _scrollView.frame.size.width);    
    //display photos in google storage.
    _googleAuth = [[GTMOAuth2Authentication alloc] init];
    _googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    [self googlePhotosService];
    NSString *username = _googleAuth.userEmail;
    NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
                                                             albumID:nil
                                                           albumName:nil
                                                             photoID:nil
                                                                kind:nil
                                                              access:nil];
    GDataServiceTicket *ticket = [_googlePhotoService fetchFeedWithURL:feedURL
                                                  delegate:self
                                         didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    //display photos in dropbox;
    [self dropClient];
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/dropbox",dir];
//    [_dropClient loadThumbnail:@"/Sfo/Photo Aug 25, 11 29 53 AM.jpg" ofSize:@"128x128" intoPath:path];
//    DropboxServiceClient *dropboxClient = [[DropboxServiceClient alloc]init];
//    [dropboxClient downloadDropboxThumbnail:path withCount:10];
    [_dropClient loadMetadata:@"/" withHash:nil];
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    [_scrollView setContentInset:UIEdgeInsetsMake(statusBarHeight+2, 0, 0, 0)];
    [_scrollView scrollRectToVisible:CGRectMake(0, 0, 320, 1) animated:YES];
    self.subImageTap = [[UITapGestureRecognizer alloc]
                        initWithTarget:self action:@selector(handleTap:)];
    [_scrollView addGestureRecognizer:self.subImageTap];
}

// album list fetch callback
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error {
    if (error == nil) {
        // load the Change Album pop-up button with the
        // album entries
        NSArray *albums = [feed entries];
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
        }
    }
}

// photo list fetch callback
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    
    NSArray *photos = [feed entries];
    int initPhotos = [photos count];
    //   int photoCount = MIN([photos count], _photoPerBlock);
    [_google_photos_lock tryLock];
    int photoCount=0;
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
        NSMutableArray *_photosWithoutSort = [[NSMutableArray alloc]init];
//        NSLog(@"Folder '%@' contains:", metadata.path);
        int i = 0;
        for (DBMetadata *file in metadata.contents) {
//            NSLog(@"\t%@", file.filename);
//            NSDictionary *thumbnailInfo = [[NSDictionary alloc]init];
//            if (file.isDirectory==YES) {
//                NSString *path = [NSString stringWithFormat: @"%@",file.path];
//                [_dropClient loadMetadata: path withHash:nil];
//            }
            [_photosWithoutSort addObject:[metadata.contents objectAtIndex:i]];
            i++;
//            if (file.isDirectory == YES) {
//                NSString *path = [NSString stringWithFormat: @"%@",file.path];
//                [_dropClient loadMetadata: path withHash:nil];
//                
//            }else{
//                //                NSLog(@"%@, %@",photoInfo.filename, photoInfo.lastModifiedDate);
//                NSString* downloadPath = [NSString stringWithFormat:@"%@/%@",_documentDir, file.filename];
//                [_dropClient loadThumbnail:file.path ofSize:@"128x128" intoPath:downloadPath];
//       //         NSLog(@"%@, %@", photoInfo.filename, photoInfo.lastModifiedDate);
//        //        [_photoThumbnails addObject:photoInfo];
//            }
        }
        NSArray* photos = [_photosWithoutSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [(DBMetadata*)a lastModifiedDate];
            NSDate *second = [(DBMetadata*)b lastModifiedDate];
            return [second compare:first];
        }];
//        [_photoThumbnails addObjectsFromArray:_photos];
        for (DBMetadata *photoInfo in photos) {
//            NSLog(@"%@, %@",photoInfo.filename, photoInfo.lastModifiedDate);
            if (photoInfo.isDirectory == YES) {
                NSString *path = [NSString stringWithFormat: @"%@",photoInfo.path];
                [_dropClient loadMetadata: path withHash:nil];

            }else{
//                NSLog(@"%@, %@", photoInfo.filename, photoInfo.lastModifiedDate);
                [_photoThumbnails addObject:photoInfo];
                _photoCount++;
                if (_photoCount <=_photoPerBlock) {
                    int index = _photoCount;
                    NSString* downloadPath = [NSString stringWithFormat:@"%@/%@",_documentDir, photoInfo.filename];
                    [_dropClient loadThumbnail:photoInfo.path ofSize:@"256x256" intoPath:downloadPath];
                    
                    //add to view
                }
            }
        }
    }
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
    [self.navigationController setNavigationBarHidden:YES];
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
    int count = 0;
    int i = 0;
    NSLog(@"beginIndex %d, endIndex %d", beginIndex, endIndex);
    while ((count<_googlePhotosIndex)&&(i<[_thumbnailLine count])) {
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
            if (beginIndex+1<endIndex) {
                beginIndex++;
                NSData *imageData1 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image1 = [[UIImage alloc]initWithData:imageData1];
                if (image1.size.height>image1.size.width) {
                    if (beginIndex+1<endIndex) {
                        beginIndex++;
                        ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                        NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                        UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                        if (image2.size.height>image2.size.width) {
                            UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(2+(_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3 , _imageHeight) ];
                            imageView1.image = image1;
                            [imageView1.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                            [imageView1.layer setBorderWidth:1.0];
                            UIImageView *imageView2 = [[UIImageView alloc]initWithFrame:CGRectMake(2+(_scrollView.frame.size.width-4)*2/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3, _imageHeight)];
                            imageView2.image = image2;
                            [imageView2.layer setBorderColor:[[UIColor whiteColor]CGColor]];
                            [imageView2.layer setBorderWidth:1.0];
                            [imageView1 setContentMode: UIViewContentModeRedraw];
                            image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                            imageView1.contentMode = UIViewContentModeScaleAspectFit;
                            image2 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                            imageView2.contentMode = UIViewContentModeScaleAspectFit;
                            [_scrollView addSubview:imageView1];
                            [_scrollView addSubview:imageView2];
                            thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width-4)/3;
                            thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width-4)*2/3;
                        }else{
                            UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*4/15 , _imageHeight) ];
                            imageView1.image = image1;
                            UIImageView *imageView2 = [[UIImageView alloc]initWithFrame:CGRectMake(2+(_scrollView.frame.size.width-4)*3/5, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*2/5, _imageHeight)];
                            imageView2.image = image2;
                            image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                            image2 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView2.frame.size.width, imageView2.frame.size.height)];
                            [_scrollView addSubview:imageView1];
                            [_scrollView addSubview:imageView2];
                            thumbnailInfo.splitCoordinate1 = 2+(_scrollView.frame.size.width-4)/3;
                            thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width-4)*3/5;
                        }
                        
                        thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                        thumbnailInfo.imageCount = 3;
                    }else{
                        UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*1/3 , _imageHeight) ];
                        imageView1.image = image1;
                        ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                        thumbnailInfo.endCoordinateX = 2+(_scrollView.frame.size.width - 4)*2/3;
                        thumbnailInfo.imageCount = 2;
                        thumbnailInfo.splitCoordinate2 = 2+(_scrollView.frame.size.width - 4)*2/3;
                        image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                        [_scrollView addSubview:imageView1];
                        return;
                    }
                }else{
                    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake((2+_scrollView.frame.size.width-4)/3, _imageHeight*(lineIndex-1), (_scrollView.frame.size.width-4)*2/3 , _imageHeight) ];
                    imageView1.image = image1;
                    ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                    thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                    thumbnailInfo.imageCount = 2;
                    image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                    [_scrollView addSubview:imageView1];
                }
            }else{
                return;
            }
        }else if(previousLineEnd < _scrollView.frame.size.width - 10){
            if (beginIndex+1<endIndex) {
                beginIndex++;
                NSData *imageData1 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image1 = [[UIImage alloc]initWithData:imageData1];
                UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(previousLineEnd, _imageHeight*(lineIndex-1), _scrollView.frame.size.width-previousLineEnd, _imageHeight) ];
                image1 = [self imageWithImage:image1 scaledToSize:CGSizeMake(imageView1.frame.size.width, imageView1.frame.size.height)];
                imageView1.image = image1;
                [_scrollView addSubview:imageView1];
                ThumbnailLineInfo *thumbnailInfo = [_thumbnailLine objectAtIndex:(lineIndex-1)];
                thumbnailInfo.endCoordinateX = _scrollView.frame.size.width - 2;
                thumbnailInfo.imageCount = 2;
            }else{
                return;
            }
        }
    }
 //   float coordinateY = lineIndex*_imageHeight;
//    i = beginIndex;
    
    while(beginIndex<endIndex) {
        NSData *imageData = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
//        NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails] objectAtIndex:2]);
        UIImage *image1 = [[UIImage alloc]initWithData:imageData];
        if(image1.size.height > image1.size.width){
            if (beginIndex+1<endIndex) {
                beginIndex++;
                GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
//                NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails] objectAtIndex:2]);
                NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                if (image2.size.height>image2.size.width) {
                    GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
 //                   NSLog(@"%@", [[[photo mediaGroup]mediaThumbnails]objectAtIndex:2]);
                    if (beginIndex+1<endIndex) {
                        beginIndex++;
                        GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
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
            }

        }else{
            if (beginIndex+1<endIndex) {
                beginIndex++;
                GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:beginIndex];
                NSData *imageData2 = [imagesData objectForKey:[NSNumber numberWithInt:beginIndex]];
                UIImage *image2 = [[UIImage alloc]initWithData:imageData2];
                UIImageView *imageView1 = [[UIImageView alloc]init];
                UIImageView *imageView2 = [[UIImageView alloc]init];
                ThumbnailLineInfo *thumbnailInfo = [[ThumbnailLineInfo alloc]init];
                if (image2.size.height>image2.size.width) {
                    float imageWidth = (_scrollView.frame.size.width - 4)/3;
                    imageView1.frame = CGRectMake(2, lineIndex*_imageHeight, imageWidth*2, _imageHeight);
                    imageView2.frame = CGRectMake(2+imageWidth*2, lineIndex*_imageHeight, imageWidth, _imageHeight);
                    thumbnailInfo.splitCoordinate1 = imageWidth;
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
            }
        }
        if (beginIndex+1<endIndex) {
            beginIndex++;
        }else{
            break;
        }
    }
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _imageHeight*lineIndex)];
    _googlePhotosIndex = beginIndex+1;
}

- (void)imageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
        // got the data; display it in the image view
 //       UIImage *image = [[UIImage alloc] initWithData:data];
        
 //       UIImageView *view = (UIImageView *)[fetcher userData];
 //       view.frame = CGRectMake(0, 0+_googleThumbnailIndex*100, 100, 100);
        NSNumber *index = [fetcher userData];
 //       [self displayThumbnail:data withIndex:[index intValue]];
 //       NSDictionary *dataInfo = [[NSDictionary alloc]init];
        [_googleThumbnails setValue:data forKey:[fetcher userData]];
        _googleFetchEndCount++;
//        int photoCount = MIN([[self.mAlbumPhotosFeed entries] count], _photoPerBlock);
        if ((_googleFetchEndCount == _googleFetchCount)||(_googleFetchEndCount == _photoPerBlock)) {
            [self displayThumbnailPage:_googleThumbnails begin:0 end:_googleFetchEndCount];
        }
     //   _googleThumbnailIndex++;
 //       [view setImage:image];
//        UIImageView *imageView = (UIImageView *)[fetcher userData];
//        UIImage *image = [[UIImage alloc] initWithData:data];
//        imageView.image = image;
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        NSLog(@"imageFetcher:%@ error:%@", fetcher,  error);
    }
}

- (void)scrollImageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
        [_googleThumbnails setValue:data forKey:[fetcher userData]];
        _googleFetchEndCount++;
        if ((_googleFetchEndCount == _googleFetchCount)||(_googleFetchEndCount == _photoPerBlock+_googlePhotosIndex)) {
            NSDictionary *subGoogleThumbnails = [[NSDictionary alloc]initWithDictionary:_googleThumbnails];
            [self displayThumbnailPage:subGoogleThumbnails begin:_googlePhotosIndex end:_googleFetchEndCount];
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

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ((_scrollBeginOffset < _scrollView.contentOffset.y)&&(_scrollView.contentOffset.y != 0.0) && (_scrollView.contentOffset.y != -0.0)){
        if ((_scrollView.contentOffset.y/_scrollView.frame.size.height>=_currentBlock)) {
            
            _currentBlock = _scrollView.contentOffset.y/_scrollView.frame.size.height;
            NSLog(@"%f, %d", _scrollView.contentOffset.y/_scrollView.frame.size.height, _currentBlock);
            _currentBlock++;
            if (_googlePhotosIndex<_googleFetchCount) {
                int endIndex = MIN(_photoPerBlock+_googlePhotosIndex, _googleFetchCount);
                [_fetchGooglePhotosLock lock];
                if (!_isDisplay) {
                    [_fetchGooglePhotosLock wait];
                }
                [_fetchGooglePhotosLock unlock];
                _isDisplay = NO;
                if ([_googleThumbnails_lock tryLock]) {
            
                    //            [_googleThumbnails_lock lock];
                    [_googleThumbnails removeAllObjects];
                    _googleFetchEndCount = _googlePhotosIndex;
//                    _googleFetchCount = endIndex;
                    for (int i = _googlePhotosIndex; i<endIndex; i++) {
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
        }
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
    GDataEntryPhoto *photo = [_googlePhotos objectAtIndex:photoIndex];
    float splitCoordinate1 = [[_thumbnailLine objectAtIndex:column] splitCoordinate1];
    float splitCoordinate2 = [[_thumbnailLine objectAtIndex:column] splitCoordinate2];
    if ((splitCoordinate1>0)&&(touchPoint.x>splitCoordinate1)) {
        if ((splitCoordinate2>0)&&(touchPoint.x>splitCoordinate2)) {
            photoIndex +=2;
        }else{
            photoIndex++;
        }
    }
    NSLog(@"%d", photoIndex);
    _tappedPhotoId = photoIndex;
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
    [self performSegueWithIdentifier:@"ActPhotoFullScreen" sender:self];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ActPhotoFullScreen"]) {
        PhotoFullScreenViewController *fullScreenVC = segue.destinationViewController;
        fullScreenVC.photos = _googlePhotos;
        fullScreenVC.photoIndex = _tappedPhotoId;
    }
}

@end
