//
//  PhotoFullScreenViewController.h
//  GGStorage
//
//  Created by lily on 3/20/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoFullScreenViewController : UIViewController<UIScrollViewDelegate>
@property NSArray *photos;
@property int photoIndex;
@end
