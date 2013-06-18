//
//  PhotoFullScreenViewController.h
//  GGStorage
//
//  Created by lily on 3/20/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoViewController.h"
#import "PhotoViewDelegate.h"

@interface PhotoFullScreenViewController : UIViewController<UIScrollViewDelegate, UIGestureRecognizerDelegate, PhotoViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property NSMutableArray *dropboxPhotos;
@property NSMutableArray *googlePhotos;
@property int photoIndex;
//1 : googleDrive
//2 : dropbox;
@property int mediaType;

@end
