//
//  ShowFolderInfoViewController.h
//  GGStorage
//
//  Created by lily on 3/26/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShowFolderInfoViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property id folderInfo;
//0:googleDrive
//1:dropbox
@property int mediaType;
@property Boolean showFullPhoto;
@property NSArray *googleCurrentList;
@property NSArray *dropboxCurrentList;
@property id currentFile;
@end
