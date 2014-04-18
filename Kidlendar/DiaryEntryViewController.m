//
//  DiaryEntryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryEntryViewController.h"
#import <MapKit/MapKit.h>
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "LocationDataStore.h"
#import "LocationData.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+Resize.h"
#import "FileManager.h"
#import "Reachability.h"
#import "GPUImage.h"
#import "PhotoLoader.h"

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface DiaryEntryViewController () <UITextViewDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
{
    UIDatePicker *datePicker;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *photoDateFormatter;

    NSArray* places;

    double locationLng;
    double locationLat;
    
    UIView *footerView;
    
    CGRect originScrollFrame;
    CGRect originLocationFrame;
    CGRect originSearchTableFrame;
    CGFloat screenHeight;

}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhotoView;
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UITextField *diaryTimeField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *diarySubjectField;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITextView *diaryEntryView;
@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *scrollViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *mainViewBackground;
//@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation DiaryEntryViewController

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
    // Do any additional setup after loading the view from its nib.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Words";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveDiary)];

    _mainViewBackground.image = _diaryImage;
    _diaryPhotoView.image =  [_diaryImage resizeImageToSize:_diaryPhotoView.frame.size];
    UIImage *croppedImage = [_mainViewBackground.image cropImageWithRectImageView:_scrollViewBackground.bounds view:_mainViewBackground];
    GPUImageiOSBlurFilter *blurFilter = [[GPUImageiOSBlurFilter alloc]init];
    _scrollViewBackground.image = [blurFilter imageByFilteringImage:croppedImage];
    
    footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 252, 320 , 36)];
    footerView.backgroundColor =  [UIColor clearColor];//[UIColor colorWithRed:0.235 green:0.729 blue:0.784 alpha:0.400];
    footerView.layer.masksToBounds = YES;
    [_scrollViewBackground addSubview:footerView];

    CALayer *backgroundLayer =[CALayer layer];
    backgroundLayer.frame = _mainViewBackground.bounds;
    backgroundLayer.backgroundColor = [[UIColor colorWithWhite:0.000 alpha:0.500]CGColor];
    [_mainViewBackground.layer addSublayer:backgroundLayer];

    // Setup Date picker
    datePicker = [[UIDatePicker alloc]init];
    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    datePicker.minuteInterval = 5;
    datePicker.date = [NSDate date];

    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd hh:mm , EEEE";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    photoDateFormatter = [[NSDateFormatter alloc]init];
    photoDateFormatter.dateFormat = @"yyyy:MM:dd hh:mm:ss";
    photoDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    _diaryEntryView.delegate = self;
    
    _diarySubjectField.delegate = self;
    [_diarySubjectField becomeFirstResponder];
    _diarySubjectField.tag = 0;
    
    _locationField.delegate = self;
    UIImageView *locationTag = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
    locationTag.image = [UIImage imageNamed:@"eventLocationLine20.png"];
    UIView *locationLeftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [locationLeftView addSubview:locationTag];
    locationTag.center = locationLeftView.center;
    _locationField.leftView = locationLeftView;
    _locationField.leftViewMode = UITextFieldViewModeAlways;
    
    _diaryTimeField.delegate = self;
    _diaryTimeField.inputView = datePicker;
    _diaryTimeField.tag = 1;
    _diaryTimeField.text = [dateFormatter stringFromDate:[NSDate date]];
    UIImageView *timeTag = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 20, 20)];
    timeTag.image = [UIImage imageNamed:@"eventCalendarLine20.png"];
    UIView *timeLeftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    [timeLeftView addSubview:timeTag];
    timeTag.center = timeLeftView.center;

    _diaryTimeField.leftView = timeLeftView;
    _diaryTimeField.leftViewMode = UITextFieldViewModeAlways;
    
    _locationSearchBar.delegate = self;
//    _locationSearchBar.tintColor = [UIColor whiteColor];
    
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    
    // Query place from Google Places using location in selected photo
    if ([_imageMeta count] > 0) {
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        if (networkStatus != NotReachable) {
            for (NSDictionary *meta in _imageMeta) {
                if ([meta count] > 0) {
                    NSDictionary *GPS = [meta objectForKey:@"{GPS}"];
                    double longitude = [[GPS objectForKey:@"Longitude"] doubleValue];
                    double latitude = [[GPS objectForKey:@"Latitude"] doubleValue];
                    [self photoLocationLongitude:longitude andLatitude:latitude];
                }
            }
        }
    }
    
    // Check photo date
    if ([_imageMeta count] > 0) {
        for (NSDictionary *meta in _imageMeta) {
            NSDictionary *TIFF = [meta objectForKey:@"{TIFF}"];
            if (TIFF) {
                NSString *dateTime = [TIFF objectForKey:@"DateTime"];
                if (dateTime) {
                    NSDate *photoDate = [photoDateFormatter dateFromString:dateTime];
                    if (photoDate) {
                        _diaryTimeField.text = [dateFormatter stringFromDate:photoDate];
                        datePicker.date = photoDate;
                    }
                }
            }
        }
    }
    _locationSearchView.layer.cornerRadius = 10.0f;
    


    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardFrameChange:(NSNotification *)notification
{
    NSDictionary *info =  notification.userInfo;
    NSValue *keyboardFrameValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];

    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    

    if (keyboardFrame.origin.y == 316 || keyboardFrame.origin.y == 228) {
        // Scroll view
        CGRect scrollFrame = _contentScrollView.frame;
//        _contentScrollView.contentSize = _contentScrollView.frame.size;
        scrollFrame.size.height -= 36;
        _contentScrollView.frame = scrollFrame;
//        NSLog(@"scroll frame %@",[NSValue valueWithCGRect:scrollFrame]);
//        NSLog(@"scroll content %@",[NSValue valueWithCGSize:_contentScrollView.contentSize]);

        // Location view
        CGRect locationFrame = _locationSearchView.frame;
        locationFrame.size.height -= 36;
        _locationSearchView.frame = locationFrame;
        
        //        // Location table view
        //        CGRect tableFrame = _searchResultTable.frame;
        //        tableFrame.size.height -= 36;
        //        _searchResultTable.frame = tableFrame;
        
        
    } else {
        _contentScrollView.frame = originScrollFrame;
//        _contentScrollView.contentSize = _contentScrollView.frame.size;
        _locationSearchView.frame = originLocationFrame;
        //        _searchResultTable.frame = originSearchTableFrame;
    }
}

- (void)viewDidLayoutSubviews
{
//    screenHeight = [[UIScreen mainScreen]bounds].size.height;
//    if( screenHeight == 480) {
//        CGRect scrollFrame = _contentScrollView.frame;
//        scrollFrame.size.height -= 88;
//        _contentScrollView.frame = scrollFrame;
//        NSLog(@"scroll frame %@",[NSValue valueWithCGRect:scrollFrame]);
//        
//        CGSize contentSize = _contentScrollView.frame.size;
//        contentSize.height = 288;
//        _contentScrollView.contentSize = contentSize;
//        NSLog(@"scroll content %@",[NSValue valueWithCGSize:contentSize]);
//        
//        
//        CGRect searchFrame = _locationSearchView.frame;
//        searchFrame.size.height -= 88;
//        _locationSearchView.frame = scrollFrame;
//    }
    
    originScrollFrame = _contentScrollView.frame;
    originLocationFrame = _locationSearchView.frame;
    originSearchTableFrame  = _searchResultTable.frame;
    
//    _contentScrollView.contentSize = _contentScrollView.frame.size;

}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    footerView.hidden = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}


#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _locationField.text = searchBar.text;
    [self queryGooglePlaceswithName:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _locationSearchView.hidden = YES;
    _contentScrollView.hidden = NO;
    footerView.hidden = NO;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    NSString *locName = [places[indexPath.row] objectForKey:@"name"];
    NSString *address = [places[indexPath.row] objectForKey:@"formatted_address"];

    cell.textLabel.text = locName;
    cell.detailTextLabel.text = address;
    cell.backgroundColor = [UIColor clearColor];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [places count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _locationField.text = [places[indexPath.row] objectForKey:@"name"];
    locationLat =  [[[[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
    locationLng =  [[[[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
    _locationSearchView.hidden = YES;
    _contentScrollView.hidden = NO;
    footerView.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)changeDate
{
    _diaryTimeField.text = [dateFormatter stringFromDate:datePicker.date];
}

- (void)saveDiary
{
    // Update diary details
    DiaryData *diary = [[DiaryDataStore sharedStore]createItem];
    
    // Diary subject
    diary.subject = _diarySubjectField.text;
    
    // Diary text , only if there's text entered
    if (_diaryEntryView.text.length > 0)
        diary.diaryText = _diaryEntryView.text;
    
    //  Diary date
    diary.dateCreated = [[dateFormatter dateFromString: _diaryTimeField.text] timeIntervalSinceReferenceDate];
    
    // Diary location
    if (_locationField.text.length > 0)
        diary.location = _locationField.text;
    
    FileManager *fm = [[FileManager alloc]initWithKey:diary.diaryKey];
    
    // Save Photo diary
    if (_selectedMediaType == kMediaTypePhoto) {
        [diary setPhotoThumbnailDataFromImage:_diaryImage];
        [fm saveCollectionImage:_diaryImage];
        PhotoLoader *loader = [[PhotoLoader alloc]initWithSourceType:kSourceTypePhoto];
        [loader createPhotoAlbum];
        [loader saveImage:_diaryImage];
    }
    // Save Video diary
    else {
        diary.diaryVideoPath = [NSString stringWithFormat:@"%@",_asset.defaultRepresentation.url];
        UIImage *image = [UIImage imageWithCGImage: _asset.defaultRepresentation.fullScreenImage];
        [diary setVideoThumbnailDataFromImage:image];
        [fm saveCollectionImage:image];
    }
    
    [[DiaryDataStore sharedStore]saveChanges];
    
    // Need location name field for diary
    if (locationLat > 0 && locationLng > 0) {
        LocationData *location = [[LocationDataStore sharedStore]createItemWithKey:diary.diaryKey];
        location.latitude = locationLat;
        location.longitude = locationLng;
        [[LocationDataStore sharedStore]saveChanges];
    }

    // Send out notification for new diary added
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryChange" object:nil];

    // Return to diary table view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeySearch) {
        if ([self checkInternetConnection]) {
            _contentScrollView.hidden = YES;
            _locationSearchView.hidden = NO;
            _locationSearchBar.text = _locationField.text;
            [self queryGooglePlaceswithName:_locationField.text];
            [_locationSearchBar becomeFirstResponder];
            footerView.hidden = YES;
            return YES;
        }else
            return NO;
    }
    if (textField.tag == 0) {
        [_diaryTimeField becomeFirstResponder];
    }
    return YES;
}

#pragma mark - Google Places Search
// Google search
-(void) queryGooglePlaceswithName:(NSString *)name
{
    NSString * language =  [[NSLocale currentLocale] localeIdentifier];
    // Sensor = true means search using GPS
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&sensor=true&language=%@&key=%@",name,language,kGOOGLE_API_KEY];

    NSURL *googleRequestURL=[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // Retrieve the results of the URL.
    
    NSURLRequest *request = [NSURLRequest requestWithURL:googleRequestURL];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if ([data length]>0 && connectionError==nil) {
                                   //收到正確的資料，連線沒有錯
                                   NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:NSJSONReadingAllowFragments
                                                                                          error:&connectionError];
                                   //The results from Google will be an array obtained from the NSDictionary object with the key "results".
                                   places = [json objectForKey:@"results"];
                                   if ([places count] > 0) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [_searchResultTable reloadData];
                                       });
                                   }
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}

-(void)photoLocationLongitude:(double)longitude andLatitude:(double)latitude
{
    // Sensor = true means search using GPS
    NSString *url  = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%F&radius=500&types=establishment&sensor=true&key=%@",latitude,longitude,kGOOGLE_API_KEY];

    
    //    NSLog(@"URL %@",url);
    //Formulate the string as a URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // Retrieve the results of the URL.
    
    NSURLRequest *request = [NSURLRequest requestWithURL:googleRequestURL];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if ([data length]>0 && connectionError==nil) {
                                   //收到正確的資料，連線沒有錯
                                   NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:NSJSONReadingAllowFragments
                                                                                          error:&connectionError];
                                   //The results from Google will be an array obtained from the NSDictionary object with the key "results".
                                   places = [json objectForKey:@"results"];
                                   if ([places count] > 0) {
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [_searchResultTable reloadData];
                                           _locationField.text = [places[0] objectForKey:@"name"];
                                       });
                                   }
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}


- (BOOL)checkInternetConnection
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *noInternetAlert = [[UIAlertView alloc]initWithTitle:@"No Internet Connection"
                                                                 message:@"Check your internet and try again"
                                                                delegate:self cancelButtonTitle:@"Close"
                                                       otherButtonTitles:nil, nil];
        [noInternetAlert show];
        return NO;
    } else {
        return YES;
    }
}

@end
