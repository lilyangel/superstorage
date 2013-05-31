//
//  GoogleAuth.h
//  GGStorage
//
//  Created by lily on 3/26/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"

@interface GoogleAuth : NSObject 
+(GDataServiceGooglePhotos*)getGooglePhotoService;
+(GTMOAuth2Authentication*)getGoogleAuth;
@end
