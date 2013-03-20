//
//  DropboxServiceClient.h
//  GGStorage
//
//  Created by lily on 3/12/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DBRestClient;

@interface DropboxServiceClient : NSObject{
    DBRestClient* restClient;
}
-(NSArray*)downloadDropboxThumbnail:(NSString*)path withCount:(NSInteger) count;
@end
