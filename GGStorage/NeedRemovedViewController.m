//
//  NeedRemovedViewController.m
//  GGStorage
//
//  Created by lily on 5/8/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "NeedRemovedViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"

@interface NeedRemovedViewController ()

@end

@implementation NeedRemovedViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    GDataServiceGoogle* service = [[GDataServiceGoogle alloc] init];
    
    [service setUserCredentialsWithUsername:@"myusername"
     
                                   password:@"mypassword"];
    NSURL* feedURL = [GDataServiceGooglePhotos
                      photoFeedURLForUserID:@"myusername"
                      
                      albumID:nil albumName:nil photoID:nil kind:nil
                      
                      access:kGDataPhotoAccessAll];
    
    GDataServiceGooglePhotos* ticket = [service
                                        fetchPhotoFeedWithURL:feedURL
                                        
                                        delegate:self
                                        
                                        didFinishSelector:@selector
                                        (albumListFetchTicket:finishedWithFeed)
                                        
                                        didFailSelector:@selector
                                        (albumListFetchTicket:failedWithError:)];
    
    //Then insert a new album entry into that feed:
    
    GDataEntryPhotoAlbum* newAlbum = [GDataEntryPhotoAlbum
                                      albumEntry]; 
    
    [newAlbum setTitleWithString:@"foo"]; 
    [newAlbum setPhotoDescriptionWithString:@"bar"]; 
    [newAlbum setAccess:kGDataPhotoAccessPublic]; 
    
    NSURL *postLinkV;// = [[feedURL postLink] URL];
    ticket = [service fetchEntryByInsertingEntry:newAlbum 
              
                                           forFeedURL:postLinkV 
              
                                             delegate:self 
              
                                    didFinishSelector:@selector 
              (albumCreationTicket:finishedWithEntry:) ]; 

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
