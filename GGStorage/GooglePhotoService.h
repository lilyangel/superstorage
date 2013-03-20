//
//  GooglePhotoService.h
//  GGStorage
//
//  Created by lily on 3/10/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GData.h"
#import "GDataFeedPhotoAlbum.h"
#import "GDataFeedPhoto.h"

@interface GooglePhotoService : NSObject{    
    GDataFeedPhotoUser *mUserAlbumFeed; // user feed of album entries
    GDataServiceTicket *mAlbumFetchTicket;
    NSError *mAlbumFetchError;
    NSString *mAlbumImageURLString;
    
    GDataFeedPhotoAlbum *mAlbumPhotosFeed; // album feed of photo entries
    GDataServiceTicket *mPhotosFetchTicket;
    NSError *mPhotosFetchError;
    NSString *mPhotoImageURLString;
}

@end
