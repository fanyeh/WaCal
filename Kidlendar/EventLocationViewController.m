//
//  EventLocationViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventLocationViewController.h"
#import "EventLocationView.h"
#import "CalendarStore.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ImageStore.h"

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface EventLocationViewController ()
{
    CGRect titleViewFrameShow;
    EventLocationView *locationView;
    UIImageView *backgroundImageView;
    GMSMapView *mapView_;
    CLGeocoder *geocoder;
    NSArray* places;
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation EventLocationViewController

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
    
    // Set up background
    backgroundImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    backgroundImageView.image = _backgroundImage;
    
    // Set up location view
    locationView = [[EventLocationView alloc]initWithFrame:CGRectMake(0, 0, 320, 352)];
    locationView.locationField.delegate = self;
    [self.view addSubview:locationView];
    locationView.locationField.text = _event.location;
    [locationView.locationField becomeFirstResponder];
    
    locationView.searchedLocationTable.dataSource = self;
    locationView.searchedLocationTable.delegate = self;
    //[locationView.searchedLocation registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    activityIndicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.center = CGPointMake(self.view.center.x, self.view.center.y - 30);
    [self.view addSubview:activityIndicator];
    [activityIndicator stopAnimating];
    
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(10, 128, 300, 210) camera:nil];
    mapView_.myLocationEnabled = YES;
    mapView_.hidden = YES;
    [self.view addSubview:mapView_];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearText)];
    [locationView.locationField.rightView addGestureRecognizer:tapGesture];
    
    // Put save button on navigation bar
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(saveLocation)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

-(void) queryGooglePlaces: (NSString *) name
{
    [locationView.searchedLocationTable setHidden:YES];
    [activityIndicator startAnimating];
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&sensor=true&language=zh-TW&key=%@",name,kGOOGLE_API_KEY];
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
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [activityIndicator stopAnimating];
                                       [locationView.searchedLocationTable setHidden:NO];
                                       [locationView.searchedLocationTable reloadData];
                                   });
                                   
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}

- (void)saveLocation
{
    _event.location = locationView.locationField.text;
    
    // Store image in the BNRImageStore with this key
    [[ImageStore sharedStore] setImage:[self captureMapImage]
                                forKey:_event.eventIdentifier];

    [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)clearText
{
    locationView.locationField.text = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITabelViewDataSource
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

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    locationView.searchedLocationTable.hidden = YES;
    mapView_.hidden = NO;
    NSDictionary *location = [[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"];
    NSString *lat = [location objectForKey:@"lat"];
    NSString *lng = [location objectForKey:@"lng"];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[lat doubleValue]
                                                            longitude:[lng doubleValue]
                                                                 zoom:15];

    [mapView_ setCamera:camera];
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
    marker.title = [places[indexPath.row] objectForKey:@"name"];
    marker.snippet = [places[indexPath.row] objectForKey:@"formatted_address"];
    marker.map = mapView_;
    locationView.locationField.text = marker.title;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self queryGooglePlaces:locationView.locationField.text];
    return YES;
}

- (UIImage *)captureMapImage
{
    UIGraphicsBeginImageContext(mapView_.frame.size);
    [mapView_.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenShotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenShotImage;
}


@end
