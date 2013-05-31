//
//  RootFoldersViewController.h
//  GGStorage
//
//  Created by lily on 3/27/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GData.h"

@interface RootFoldersViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property int mediaType;
@property Boolean showFullPhoto;
@property NSArray *googleCurrentList;
@property NSArray *dropboxCurrentList;
@property id currentFile;
@end
