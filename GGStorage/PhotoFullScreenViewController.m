//
//  PhotoFullScreenViewController.m
//  GGStorage
//
//  Created by lily on 3/20/13.
//  Copyright (c) 2013 lily. All rights reserved.
//

#import "PhotoFullScreenViewController.h"
#import "GData.h"
#import "GDataServiceGooglePhotos.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GlobalSetting.h"
#import <QuartzCore/CALayer.h>

@interface PhotoFullScreenViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableDictionary *imageSet;
@property (nonatomic) NSMutableData *receivedData;
@property (nonatomic) NSInteger photoCount;
@property float scrollBeginOffset;
@property (nonatomic) NSInteger beginPhotoIndex;
@property (nonatomic) NSInteger endPhotoIndex;
@property Boolean isDisplayToolBar;
@end

@implementation PhotoFullScreenViewController
@synthesize photos = _photos;
@synthesize photoIndex = _photoIndex;
@synthesize connection = _connection;
@synthesize imageSet = _imageSet;
@synthesize receivedData = _receivedData;
@synthesize photoCount = _photoCount;
@synthesize scrollBeginOffset = _scrollBeginOffset;
@synthesize beginPhotoIndex = _beginPhotoIndex;
@synthesize endPhotoIndex = _endPhotoIndex;
@synthesize isDisplayToolBar = _isDisplayToolBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _isDisplayToolBar = NO;
    _imageSet = [[NSMutableDictionary alloc] init];
    GDataEntryPhoto *photo = [_photos objectAtIndex:_photoIndex];
    NSLog(@"%@", [photo.mediaGroup mediaContents]);
    _photoCount = [_photos count];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UILabel * nav_title = [[UILabel alloc] initWithFrame:CGRectMake(80, 2, 220, 25)];
    nav_title.font = [UIFont fontWithName:@"Arial-BoldMT" size:18];
    nav_title.textColor = [UIColor whiteColor];
    nav_title.adjustsFontSizeToFitWidth = YES;
    nav_title.text = [[[photo mediaGroup] mediaTitle]stringValue];
    nav_title.backgroundColor = [UIColor clearColor];
//    self.navigationController.navigationBar.topItem.title = [[[photo mediaGroup] mediaTitle]stringValue];
    [self.navigationController.navigationBar addSubview:nav_title];
    self.scrollView.delegate=self;
    [_scrollView setContentSize:CGSizeMake(_scrollView.bounds.size.width * (_photoCount), _scrollView.bounds.size.height)];
    _beginPhotoIndex = _photoIndex;
    _endPhotoIndex = _photoIndex;
    [self imageAtIndex:_photoIndex];
    if (_photoIndex-1 >= 0) {
        [self imageAtIndex:_photoIndex-1];
        _beginPhotoIndex--;
        
    }
    if (_photoIndex+1 < _photoCount){
        [self imageAtIndex:_photoIndex+1];
        _endPhotoIndex++;
    }
    [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
    
    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(handlePhotoTap:)];
    [_scrollView addGestureRecognizer:imageTap];
}



-(void)handlePhotoTap:(UITapGestureRecognizer*)gesture
{
    if (_isDisplayToolBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }else{
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void) imageAtIndex:(NSUInteger) photoIndex
{
    if(photoIndex>=_photoCount)
        return;
    GDataEntryPhoto *photo = [_photos objectAtIndex:photoIndex];
    NSURL *urlString = [NSURL URLWithString:[[[[photo mediaGroup]mediaContents]objectAtIndex:0]URLString]];
    [self sendGetPhotoDataRequest:urlString withPhotoIndex:photoIndex];
    return;
}


- (void)sendGetPhotoDataRequest:(NSURL*)urlString withPhotoIndex:(int)photoIndex
{
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:urlString cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    _connection = [[NSURLConnection alloc ] initWithRequest:theRequest delegate:self];
    
    _receivedData = [[NSMutableData alloc ] init];
    
    NSMutableDictionary *dataAndPhotoIndex = [[NSMutableDictionary alloc] init];
    [dataAndPhotoIndex setObject:_receivedData forKey:[NSString stringWithFormat:@"%d", photoIndex]];
    NSMutableDictionary *imageAndURL = [[NSMutableDictionary alloc] init];
    [imageAndURL setObject:dataAndPhotoIndex forKey:urlString];
    [_imageSet setObject:imageAndURL forKey:_connection.description];
    dataAndPhotoIndex = nil;
    imageAndURL = nil;
    
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSMutableDictionary *imageAndRUL = [_imageSet objectForKey:connection.description];
    NSMutableData *theReceived = [[[imageAndRUL objectForKey:response.URL] allValues]objectAtIndex:0];
    [theReceived setLength:0];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSMutableDictionary *imageAndRUL = [_imageSet objectForKey:connection.description];
    NSMutableData *theReceived = [[[[imageAndRUL allValues] objectAtIndex:0] allValues]objectAtIndex:0];
    [theReceived appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSMutableData *theReceived = [_imageSet objectForKey:[connection description]];
    theReceived = nil;
    connection = nil;
    NSLog(@"connection failed,ERROR %@", [error localizedDescription]);
    [[[UIAlertView alloc]
      initWithTitle:@"Downloading Error" message:nil
      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
     show];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSMutableDictionary *imageAndURL = [_imageSet objectForKey:connection.description];
    if (imageAndURL == nil) {
        return;
    }
    
    NSMutableData *theReceived = [[[[imageAndURL allValues] objectAtIndex:0] allValues]objectAtIndex:0];
        
    if (theReceived == nil) {
        NSLog(@"No image data");
    }
    
    int photoIndex = [[[[[imageAndURL allValues] objectAtIndex:0] allKeys]objectAtIndex:0] intValue];
    [self displayImage:[UIImage imageWithData:theReceived] withPageIndex:photoIndex];
    
    //store to local
    [_imageSet removeObjectForKey:connection.description];
    [self setConnection: nil];
    
}

- (void) displayImage:(UIImage *)image withPageIndex:(NSInteger)pageIndex
{
    if (image == nil) {
        return;
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(_scrollView.bounds.size.width*pageIndex, 0, _scrollView.bounds.size.width, _scrollView.bounds.size.height);
    [imageView.layer setBorderWidth:5.0];
    [imageView.layer setBorderColor:[[UIColor blackColor] CGColor]];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [_scrollView addSubview:imageView];
    imageView = nil;
    image = nil;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _scrollBeginOffset = scrollView.contentOffset.x;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ((_scrollBeginOffset < _scrollView.contentOffset.x)&&(_scrollView.contentOffset.x != 0.0) && (_scrollView.contentOffset.x != -0.0)&&(_photoIndex<_photoCount-1)) {
        _photoIndex++;
        [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
        if ((_endPhotoIndex +1 < _photoCount) &&(_endPhotoIndex == _photoIndex)) {
            _endPhotoIndex++;
            [self imageAtIndex:_endPhotoIndex];
            if (_photoIndex - _beginPhotoIndex >= 2) {
                for (UIImageView *imageView in [_scrollView subviews]) {
                    float distance = imageView.frame.origin.x-5 - _scrollView.bounds.size.width * _beginPhotoIndex;
                    if ((distance<(float)10.0) && (distance > (float)(-10.0))) {
                        [imageView removeFromSuperview];
                        imageView.image = nil;
                        _beginPhotoIndex++;
                        break;
                    }
                }
            }
        }
        
    }else if((_scrollBeginOffset > _scrollView.contentOffset.x)&&(_photoIndex>0)){
        _photoIndex--;
        [_scrollView setContentOffset:CGPointMake(_scrollView.bounds.size.width*_photoIndex, 0)];
        if ((_beginPhotoIndex - 1 >= 0)&&(_beginPhotoIndex == _photoIndex)) {
            _beginPhotoIndex--;
            [self imageAtIndex:_beginPhotoIndex];
            if (_endPhotoIndex - _photoIndex >= 2) {
                for (UIImageView *imageView in [_scrollView subviews]) {
                    float distance = imageView.frame.origin.x-5 - _scrollView.bounds.size.width * _endPhotoIndex;
                    if ((distance<(float)10.0) && (distance > (float)(-10.0))) {
                        [imageView removeFromSuperview];
                        imageView.image = nil;
                        _endPhotoIndex--;
                        break;
                    }
                }
            }
        }
    }else{
        return;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

@end
