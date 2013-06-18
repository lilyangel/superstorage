//
//  PhotoViewController.h
//  GGStorage
//
//  Created by lily on 3/12/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoFullScreenViewController.h"
#import "PhotoViewDelegate.h"

@interface PhotoViewController : UIViewController<UIScrollViewDelegate>
@property id<PhotoViewDelegate> delegate;
@end
