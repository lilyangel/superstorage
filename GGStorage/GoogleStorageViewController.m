//
//  GoogleStorageViewController.m
//  GGStorage
//
//  Created by lily on 3/10/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "GoogleStorageViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"

@interface GoogleStorageViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property GDataFeedPhotoAlbum *mAlbumPhotosFeed;
@property (nonatomic, retain) GTMOAuth2Authentication *googleAuth;
@end
//NSString * const kGTMOAuth2AccountName = @"OAuth";
//static NSString *const kKeychainItemName = @"Google Drive Quickstart";
//static NSString *const kClientID = @"81720981197.apps.googleusercontent.com";
//static NSString *const kClientSecret = @"EjZNvAXWx7D79EnvyHOpiw4W";
@implementation GoogleStorageViewController
@synthesize mAlbumPhotosFeed;
@synthesize scrollView = _scrollView;
@synthesize googleAuth = _googleAuth;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    NSURL *albumURL = [GDataServiceGooglePhotos
//                       photoFeedURLForUserID:@"lilyangel007@gmail.com" albumID:nil
//                       albumName:@"MyBestPhotos" photoID:nil kind:nil access:nil];
//    GDataQueryGooglePhotos *introspectQuery;
//    introspectQuery = [GDataQueryGooglePhotos photoQueryWithFeedURL:albumURL];
//    [introspectQuery setResultFormat:kGDataQueryResultServiceDocument];
//    GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
//    
//    [service setShouldCacheResponseData:YES];
//    [service setServiceShouldFollowNextLinks:YES];
//    GDataServiceTicket *ticket;
//    ticket = [service fetchFeedWithQuery:introspectQuery
//                                      delegate:self
//                             didFinishSelector:nil];
    
//    GDataServiceGooglePhotos *service = [self googlePhotosService];
    
//    NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
//                                                             albumID:nil
//                                                           albumName:nil
//                                                             photoID:nil
//                                                                kind:nil
//                                                              access:nil];
//   GDataServiceTicket *ticket = [service fetchFeedWithURL:feedURL
//                              delegate:self
//                     didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height*2)];
}

-(void)viewWillAppear:(BOOL)animated
{
    //    CFTypeRef passwordData = [self searchKeychainCopyMatching:@"Password"];
//    GTMOAuth2Keychain *keychain = [GTMOAuth2Keychain defaultKeychain];
//    NSString *password = [keychain passwordForService:@"Google Drive Quickstart"
//                                              account:kGTMOAuth2AccountName
//                                                error:nil];
    GDataServiceGooglePhotos *service = [self googlePhotosService];
    NSString *username = @"lilyangel007@gmail.com";
    NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
                                                             albumID:nil
                                                           albumName:nil
                                                             photoID:nil
                                                                kind:nil
                                                              access:nil];
    GDataServiceTicket *ticket = [service fetchFeedWithURL:feedURL
                              delegate:self
                     didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
}

- (GDataServiceGooglePhotos *)googlePhotosService {
    
    static GDataServiceGooglePhotos* service = nil;
    
    if (!service) {
        service = [[GDataServiceGooglePhotos alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
    }
    
    _googleAuth = [[GTMOAuth2Authentication alloc] init];
    _googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    [service setAuthorizer:_googleAuth];
    // update the username/password each time the service is requested
//    NSString *username = @"lilyangel007";
//    NSString *password = @"FigoLove920%";
//    NSString *username = nil;
//    NSString *password = nil;
//     
//    if ([username length] && [password length]) {
//        [service setUserCredentialsWithUsername:username
//                                       password:password];
//    } else {
//        [service setUserCredentialsWithUsername:nil
//                                       password:nil];
//    }
    
    return service;
}

//- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
//    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
//    
//    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
//    
//    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
//    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
//    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
//    [searchDictionary setObject:@"Google Drive Quickstart" forKey:(__bridge id)kSecAttrService];
//    
//    return searchDictionary;
//}
//
//- (CFTypeRef *)searchKeychainCopyMatching:(NSString *)identifier {
//    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
//    
//    // Add search attributes
//    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
//    
//    // Add search return types
//    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
//    
//    CFTypeRef *result = nil;
//    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary,
//                                          result);
//    NSLog(@"%@",result);
//    return result;
//}


// photo list fetch callback
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    
    self.mAlbumPhotosFeed = feed;
    NSArray *photos = [self.mAlbumPhotosFeed entries];
    for (int i = 0; i< [photos count]; i++){
        GDataEntryPhoto *photo = [photos objectAtIndex:i];
        NSArray *thumbnails = [[photo mediaGroup]mediaThumbnails];
        if ([thumbnails count] > 0){
            NSString *imageURLString = [[thumbnails objectAtIndex:0] URLString];
            NSLog(@"%@", imageURLString);
            UIImageView *view = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0+i*100, 100, 100)];
            [_scrollView addSubview:view];
            GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:imageURLString];
            
            // use the fetcher's userData to remember which image view we'll display
            // this in once the fetch completes
            [fetcher setUserData:view];
            
            // http logs are more readable when fetchers have comments
            [fetcher setCommentWithFormat:@"thumbnail for test"];
            
            [fetcher beginFetchWithDelegate:self
                          didFinishSelector:@selector(imageFetcher:finishedWithData:error:)];
            
        }
    }
//    [self setPhotoFetchError:error];
//    [self setPhotoFetchTicket:nil];
    
 //   [self updateUI];
}

- (void)imageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
        // got the data; display it in the image view
        UIImage *image = [[UIImage alloc] initWithData:data];
        
        UIImageView *view = (UIImageView *)[fetcher userData];
        [view setImage:image];
        
    } else {
        NSLog(@"imageFetcher:%@ error:%@", fetcher,  error);
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
