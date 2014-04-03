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
    BOOL hasText;
//    BOOL locationFirstLoad;
}
@property (weak, nonatomic) IBOutlet UIView *searchMaskView;
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhotoView;
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UITextField *diaryTimeField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *diarySubjectField;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITextView *diaryEntryView;
@property (weak, nonatomic) IBOutlet UIView *videoPlayView;
@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *scrollViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *mainViewBackground;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

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
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Words";
//    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveDiary:)];
//    self.navigationItem.rightBarButtonItem = saveButton;
    _saveButton.layer.masksToBounds = YES;
    _saveButton.layer.cornerRadius = _saveButton.frame.size.width/2;
    
    _deleteButton.layer.masksToBounds = YES;
    _deleteButton.layer.cornerRadius = _saveButton.frame.size.width/2;
    
    if ([_asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
        _videoPlayView.layer.cornerRadius = _videoPlayView.frame.size.width/2;
        _videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
        _videoPlayView.layer.borderWidth = 2.0f;
        _videoPlayView.hidden = NO;
    }
    
    _mainViewBackground.image = _diaryImage;
    _diaryPhotoView.image =  [_diaryImage resizeImageToSize:_diaryPhotoView.frame.size];
    UIImage *croppedImage = [_mainViewBackground.image cropImageWithRectImageView:_scrollViewBackground.bounds view:_mainViewBackground];
    GPUImageiOSBlurFilter *blurFilter = [[GPUImageiOSBlurFilter alloc]init];
    _scrollViewBackground.image = [blurFilter imageByFilteringImage:croppedImage];
    _scrollViewBackground.layer.masksToBounds = YES;
    _scrollViewBackground.layer.cornerRadius = 5.0f;

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
    dateFormatter.dateFormat = @"yyyy/MM/dd";
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
    _locationSearchBar.tintColor = MainColor;
    
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    
    // Query place from Google Places using location in selected photo
    if ([_imageMeta count] > 0) {
        for (NSDictionary *meta in _imageMeta) {
//            NSDictionary *GPS = [meta objectForKey:@"{GPS}"];
//            double longitude = [[GPS objectForKey:@"Longitude"] doubleValue];
//            double latitude = [[GPS objectForKey:@"Latitude"] doubleValue];
//            [self queryGooglePlacesLongitude:longitude andLatitude:latitude withName:nil];
            
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
//    } else {
//        locationFirstLoad = NO;
    }
    _locationSearchView.layer.cornerRadius = 10.0f;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}


#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _locationField.text = searchBar.text;
    [self queryGooglePlacesLongitude:0 andLatitude:0 withName:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _locationSearchView.hidden = YES;
    _contentView.hidden = NO;
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
    _contentView.hidden = NO;
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
- (IBAction)deleteDiary:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)saveDiary:(id)sender
{
    // Update diary details
    DiaryData *diary = [[DiaryDataStore sharedStore]createItem];
    
    diary.subject = _diarySubjectField.text;
    if (hasText || ([_diaryEntryView isFirstResponder] && _diaryEntryView.text.length > 0)) {
        diary.diaryText = _diaryEntryView.text;
    }
    
    diary.dateCreated = [[dateFormatter dateFromString: _diaryTimeField.text] timeIntervalSinceReferenceDate];
    
    if (_locationField.text.length > 0)
        diary.location = _locationField.text;
    
    FileManager *fm = [[FileManager alloc]initWithKey:diary.diaryKey];
    
    // Photo diary
    if (_selectedMediaType == kMediaTypePhoto) {
        [diary setPhotoThumbnailDataFromImage:_diaryImage];
        [fm saveCollectionImage:_diaryImage];
    }
    // Video diary
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

//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
//{
//    if (textField.tag == 9 && locationFirstLoad) {
//        if ([self checkInternetConnection]) {
//            [_locationSearchBar becomeFirstResponder];
//            _searchMaskView.hidden = NO;
//            locationFirstLoad = NO;
//        }
//    }
//    return YES;
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeySearch) {
        if ([self checkInternetConnection]) {
            _contentView.hidden = YES;
            _locationSearchView.hidden = NO;
            _locationSearchBar.text = _locationField.text;
            [self queryGooglePlacesLongitude:0 andLatitude:0 withName:_locationField.text];
            [_locationSearchBar becomeFirstResponder];
            return YES;
        }else
            return NO;
    }
    if (textField.tag == 0) {
        [_diaryTimeField becomeFirstResponder];
    }
    return YES;
}

#pragma mark - UITextViewDelegate

//- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
//{
//    if (!hasText) {
//        _diaryEntryView.text = @"";
//        _diaryEntryView.textColor = [UIColor colorWithWhite:0.400 alpha:1.000];
//    }
//    return YES;
//}
//
//- (void)textViewDidEndEditing:(UITextView *)textView
//{
//    if(_diaryEntryView.text.length == 0){
//        _diaryEntryView.textColor = [UIColor colorWithWhite:0.667 alpha:1.000];
//        _diaryEntryView.text = @"This moment...";
//        hasText = NO;
//    } else 
//        hasText = YES;
//}

#pragma mark - Google Places Search
// Google search
-(void) queryGooglePlacesLongitude:(double)longitude andLatitude:(double)latitude withName:(NSString *)name
{
    // Sensor = true means search using GPS
    NSString *url;
    if (!name) {
        url  = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%f,%F&radius=100&sensor=true&key=%@",latitude,longitude,kGOOGLE_API_KEY];
    } else {
        url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&sensor=true&language=zh-TW&key=%@",name,kGOOGLE_API_KEY];
    }

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
        UIAlertView *noInternetAlert = [[UIAlertView alloc]initWithTitle:nil message:@"No Internet Connection" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [noInternetAlert show];
        return NO;
    } else {
        return YES;
    }
}

@end
