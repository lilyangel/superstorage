//
//  GoogleAuth.m
//  GGStorage
//
//  Created by lily on 3/26/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "GoogleAuth.h"
@interface GoogleAuth()
@end
static GDataServiceGooglePhotos *googlePhotoService;
static GTMOAuth2Authentication *googleAuth;
@implementation GoogleAuth

+(GTMOAuth2Authentication*)getGoogleAuth{
    if (!googleAuth) {
        googleAuth = [[GTMOAuth2Authentication alloc] init];
    }
    googleAuth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
    return googleAuth;
}

+(GDataServiceGooglePhotos*)getGooglePhotoService{    
    if (!googlePhotoService) {
        googlePhotoService = [[GDataServiceGooglePhotos alloc] init];
        [googlePhotoService setShouldCacheResponseData:YES];
        [googlePhotoService setServiceShouldFollowNextLinks:YES];
    }
    [googlePhotoService setAuthorizer:[self getGoogleAuth]];
    
    return googlePhotoService;
}
@end
