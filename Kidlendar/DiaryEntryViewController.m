//
//  DiaryEntryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryEntryViewController.h"
#import <MapKit/MapKit.h>
//#import <GoogleMaps/GoogleMaps.h>
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "LocationDataStore.h"
#import "LocationData.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface DiaryEntryViewController () <UITextViewDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>
{
    UIDatePicker *datePicker;
    NSDateFormatter *dateFormatter;
    NSArray* places;
    double locationLng;
    double locationLat;
}
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIView *diaryComposeView;
@property (weak, nonatomic) IBOutlet UITextField *diaryTimeField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *diarySubjectField;
@property (weak, nonatomic) IBOutlet UIButton *diaryLocationIconButton;
@property (weak, nonatomic) IBOutlet UIImageView *diaryTimeIcon;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITextView *diaryEntryView;
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


    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(saveDiary)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Setup Date picker
    datePicker = [[UIDatePicker alloc]init];
    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    datePicker.minuteInterval = 5;
    datePicker.date = [NSDate date];

    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy年MM月dd日 EEEE HH:mm";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    _diaryEntryView.delegate = self;
    _diaryEntryView.layer.borderColor = [[UIColor colorWithWhite:0.498 alpha:1.000] CGColor];
    _diaryEntryView.layer.borderWidth = 1.0f;
    _diaryEntryView.layer.cornerRadius = 5.0f;
    
    _diarySubjectField.delegate = self;
    [_diarySubjectField becomeFirstResponder];
    _diarySubjectField.tag = 0;
    
    _locationField.delegate = self;
    
    _locationSearchBar.delegate = self;
    
    _diaryTimeField.delegate = self;
    _diaryTimeField.inputView = datePicker;
    _diaryTimeField.tag = 1;
    
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    [_searchResultTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    for (NSDictionary *meta in _imageMeta) {
        NSDictionary *GPS = [meta objectForKey:@"{GPS}"];
        double longitude = [[GPS objectForKey:@"Longitude"] doubleValue];
        double latitude = [[GPS objectForKey:@"Latitude"] doubleValue];
        [self queryGooglePlacesLongitude:longitude andLatitude:latitude withName:nil];
    }
    
    _locationSearchView.layer.cornerRadius = 10.0f;
    
}
- (IBAction)locationBtnAction:(id)sender
{
    _maskView.hidden = NO;
    [_locationSearchBar becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}


#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _locationField.text = searchBar.text;
    [self queryGooglePlacesLongitude:0 andLatitude:0 withName:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _maskView.hidden = YES;
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
    _maskView.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Apple search
//- (void)startSearchForText:(NSString*)searchText
//{
//    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
//    searchRequest.naturalLanguageQuery = searchText;
//    
//    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
//    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
//        if (response.mapItems.count > 0) {
//            places = [response.mapItems copy];
//            [_searchResultTable reloadData];
//            
//        } else {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
//                                                            message:@"No search results found! Try again with a different query."
//                                                           delegate:nil
//                                                  cancelButtonTitle:nil
//                                                  otherButtonTitles:@"OK", nil];
//            [alert show];
//        }
//    }];
//}


-(void)changeDate
{
    _diaryTimeField.text = [dateFormatter stringFromDate:datePicker.date];
}

- (void)saveDiary
{
    // Update diary details
    DiaryData *diary = [[DiaryDataStore sharedStore]createItem];
    diary.subject = _diarySubjectField.text;
    diary.diaryImageDataFromImage = _diaryImage;
    diary.diaryText = _diaryEntryView.text;
    diary.dateCreated = [[dateFormatter dateFromString: _diaryTimeField.text] timeIntervalSinceReferenceDate];
    diary.location = _locationField.text;
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeySearch) {
        _locationSearchBar.text = _locationField.text;
        [self queryGooglePlacesLongitude:0 andLatitude:0 withName:_locationField.text];
        _maskView.hidden = NO;
        [_locationSearchBar becomeFirstResponder];
    }
    [textField resignFirstResponder];
    if (textField.tag == 0) {
        [_diaryTimeField becomeFirstResponder];
    }
    return YES;
}

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

    NSLog(@"URL %@",url);
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
//                                   NSLog(@"Places %@",places);
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [_searchResultTable reloadData];
                                   });
                                   
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}

@end
