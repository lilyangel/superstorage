//
//  GooglePhotoService.m
//  GGStorage
//
//  Created by lily on 3/10/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "GooglePhotoService.h"
#import "GDataServiceGooglePhotos.h"
#import "GDataEntryPhotoAlbum.h"
#import "GDataEntryPhoto.h"
#import "GDataFeedPhoto.h"

@interface GooglePhotoService()
- (void)updateUI;

- (void)fetchAllAlbums;
- (void)fetchSelectedAlbum;

- (void)createAnAlbum;
- (void)addAPhotoToUploadURL:(NSURL *)url;
- (void)deleteSelectedPhoto;
- (void)downloadSelectedPhoto;
- (void)moveSelectedPhotoToAlbum:(GDataEntryPhotoAlbum *)albumEntry;

- (void)addTagToSelectedPhoto;
- (void)addCommentToSelectedPhoto;
- (void)postToSelectedPhotoEntry:(GDataEntryPhotoBase *)entry;

- (GDataServiceGooglePhotos *)googlePhotosService;
- (GDataEntryPhotoAlbum *)selectedAlbum;
- (GDataEntryPhoto *)selectedPhoto;

- (GDataFeedPhotoUser *)albumFeed;
- (void)setAlbumFeed:(GDataFeedPhotoUser *)feed;
- (NSError *)albumFetchError;
- (void)setAlbumFetchError:(NSError *)error;
- (GDataServiceTicket *)albumFetchTicket;
- (void)setAlbumFetchTicket:(GDataServiceTicket *)ticket;
- (NSString *)albumImageURLString;
- (void)setAlbumImageURLString:(NSString *)str;

- (GDataFeedPhotoAlbum *)photoFeed;
- (void)setPhotoFeed:(GDataFeedPhotoAlbum *)feed;
- (NSError *)photoFetchError;
- (void)setPhotoFetchError:(NSError *)error;
- (GDataServiceTicket *)photoFetchTicket;
- (void)setPhotoFetchTicket:(GDataServiceTicket *)ticket;
- (NSString *)photoImageURLString;
- (void)setPhotoImageURLString:(NSString *)str;

- (void)uploadPhotoAtPath:(NSString *)photoPath uploadURL:(NSURL *)uploadURL;

@property NSString *mUsernameField;

@end

@implementation GooglePhotoService
@synthesize mUsernameField;

// fetch or clear the thumbnail for this specified album
- (void)updateImageForAlbum:(GDataEntryPhotoAlbum *)album {
        
        NSArray *thumbnails = [[album mediaGroup] mediaThumbnails];
        if ([thumbnails count] > 0) {
            
            NSString *imageURLString = [[thumbnails objectAtIndex:0] URLString];
            if (!imageURLString || ![mAlbumImageURLString isEqual:imageURLString]) {
                
                [self setAlbumImageURLString:imageURLString];
            }
        }
}

// get or clear the thumbnail for this specified photo
- (void)updateImageForPhoto:(GDataEntryPhoto *)photo {
    
        // if the new thumbnail URL string is different from the previous one,
        // save the new one, clear the image and fetch the new image
        
        NSArray *thumbnails = [[photo mediaGroup] mediaThumbnails];
        if ([thumbnails count] > 0) {
            
            NSString *imageURLString = [[thumbnails objectAtIndex:0] URLString];
            if (!imageURLString || ![mPhotoImageURLString isEqual:imageURLString]) {
                
                [self setPhotoImageURLString:imageURLString];
            }
        }
}

#pragma mark -

// get an album service object with the current username/password
//
// A "service" object handles networking tasks.  Service objects
// contain user authentication information as well as networking
// state information (such as cookies and the "last modified" date for
// fetched data.)

- (GDataServiceGooglePhotos *)googlePhotosService {
    
    static GDataServiceGooglePhotos* service = nil;
    
    if (!service) {
        service = [[GDataServiceGooglePhotos alloc] init];
        
        [service setShouldCacheResponseData:YES];
        [service setServiceShouldFollowNextLinks:YES];
    }
    
    // update the username/password each time the service is requested
    NSString *username = @"lilyangel007@gmailc.om";
    NSString *password = @"FigoLove920%";
    if ([username length] && [password length]) {
        [service setUserCredentialsWithUsername:username
                                       password:password];
    } else {
        [service setUserCredentialsWithUsername:nil
                                       password:nil];
    }
    
    return service;
}

// get the album selected in the top list, or nil if none
- (GDataEntryPhotoAlbum *)selectedAlbum {
    
    NSArray *albums = [mUserAlbumFeed entries];
    int rowIndex = 0;
    if ([albums count] > 0 && rowIndex > -1) {
        
        GDataEntryPhotoAlbum *album = [albums objectAtIndex:rowIndex];
        return album;
    }
    return nil;
}

// get the photo selected in the bottom list, or nil if none
- (GDataEntryPhoto *)selectedPhoto {
    
    NSArray *photos = [mAlbumPhotosFeed entries];
    int rowIndex = 0;
    if ([photos count] > 0 && rowIndex > -1) {
        
        GDataEntryPhoto *photo = [photos objectAtIndex:rowIndex];
        return photo;
    }
    return nil;
}

#pragma mark Fetch all albums

// begin retrieving the list of the user's albums
- (void)fetchAllAlbums {
    
    [self setAlbumFeed:nil];
    [self setAlbumFetchError:nil];
    [self setAlbumFetchTicket:nil];
    
    [self setPhotoFeed:nil];
    [self setPhotoFetchError:nil];
    [self setPhotoFetchTicket:nil];
    
    NSString *username = mUsernameField;
    
    GDataServiceGooglePhotos *service = [self googlePhotosService];
    GDataServiceTicket *ticket;
    
    NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:username
                                                             albumID:nil
                                                           albumName:nil
                                                             photoID:nil
                                                                kind:nil
                                                              access:nil];
    ticket = [service fetchFeedWithURL:feedURL
                              delegate:self
                     didFinishSelector:@selector(albumListFetchTicket:finishedWithFeed:error:)];
    [self setAlbumFetchTicket:ticket];
    
    [self updateUI];
}

// album list fetch callback
- (void)albumListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedPhotoUser *)feed
                       error:(NSError *)error {
    [self setAlbumFeed:feed];
    [self setAlbumFetchError:error];
    [self setAlbumFetchTicket:nil];
    
//    if (error == nil) {
//        // load the Change Album pop-up button with the
//        // album entries
//        [self updateChangeAlbumList];
//    }
//    
    [self updateUI];
}

#pragma mark Fetch an album's photos

// for the album selected in the top list, begin retrieving the list of
// photos
- (void)fetchSelectedAlbum {
    
    GDataEntryPhotoAlbum *album = [self selectedAlbum];
    if (album) {
        
        // fetch the photos feed
        NSURL *feedURL = [[album feedLink] URL];
        if (feedURL) {
            [self setPhotoFeed:nil];
            [self setPhotoFetchError:nil];
            [self setPhotoFetchTicket:nil];
            
            GDataServiceGooglePhotos *service = [self googlePhotosService];
            GDataServiceTicket *ticket;
            ticket = [service fetchFeedWithURL:feedURL
                                      delegate:self
                             didFinishSelector:@selector(photosTicket:finishedWithFeed:error:)];
            [self setPhotoFetchTicket:ticket];
            
            [self updateUI];
        }
    }
}

// photo list fetch callback
- (void)photosTicket:(GDataServiceTicket *)ticket
    finishedWithFeed:(GDataFeedPhotoAlbum *)feed
               error:(NSError *)error {
    
    [self setPhotoFeed:feed];
    [self setPhotoFetchError:error];
    [self setPhotoFetchTicket:nil];
    
    [self updateUI];
}

@end
