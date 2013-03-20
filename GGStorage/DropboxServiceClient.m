//
//  DropboxServiceClient.m
//  GGStorage
//
//  Created by lily on 3/12/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "DropboxServiceClient.h"
#import <DropboxSDK/DropboxSDK.h>

@interface DropboxServiceClient()<DBRestClientDelegate>
@property (nonatomic, readonly) DBRestClient* restClient;
@end
//static DBRestClient *restClient;
@implementation DropboxServiceClient

//@synthesize restClient = _restClient;


#pragma mark DBRestClientDelegate methods
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            NSLog(@"\t%@", file.filename);
        }
    }
}

- (void)restClient:(DBRestClient *)client
loadMetadataFailedWithError:(NSError *)error {
    
    NSLog(@"Error loading metadata: %@", error);
}
-(NSArray*)downloadDropboxThumbnail:(NSString*)path withCount:(NSInteger)count
{
//    [self restClient];
 //   [_restClient loadThumbnail:@"/Sfo/Photo Aug 25, 11 29 53 AM.jpg" ofSize:@"128x128" intoPath:path];
//    [_restClient loadMetadata:@"/Sfo"];
    [self.restClient loadMetadata:@"/0" withHash:nil];
    
//    if (path == nil) {
//        
//    }
    return nil;
}

//
//- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
//{    
//    NSArray* validExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", nil];
//    NSMutableArray* newPhotoPaths = [NSMutableArray new];
//    for (DBMetadata* child in metadata.contents) {
//        NSString* extension = [[child.path pathExtension] lowercaseString];
//        if (!child.isDirectory && [validExtensions indexOfObject:extension] != NSNotFound) {
//            [newPhotoPaths addObject:child.path];
//        }
//    }
//    [photoPaths release];
//    photoPaths = newPhotoPaths;
//    [self loadRandomPhoto];
//}
- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    return restClient;
}
@end
