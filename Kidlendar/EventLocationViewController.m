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

#define kGOOGLE_API_KEY @"AIzaSyC3mzoJiHuSh6p6K0UaekKtMXNYZ60hdGE"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface EventLocationViewController ()
{
    CGRect titleViewFrameShow;
    EventLocationView *locationView;
    UIImageView *backgroundImageView;
    GMSMapView *mapView_;
    CLGeocoder *geocoder;
    NSArray* places;
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
    
    locationView.searchedLocation.dataSource = self;
    locationView.searchedLocation.delegate = self;
    [locationView.searchedLocation registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMap)];
    [locationView.locationField.rightView addGestureRecognizer:tapGesture];
    
    // Put save button on navigation bar
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(saveLocation)];
    self.navigationItem.rightBarButtonItem = saveButton;

}

-(void) queryGooglePlaces: (NSString *) name {
    // Build the url string to send to Google. NOTE: The kGOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication

    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&sensor=true&language=zh-TW&key=%@",name,kGOOGLE_API_KEY];
    NSLog(@"URL %@",url);
    //Formulate the string as a URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

-(void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    NSLog(@"error %@",error);
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    places = [json objectForKey:@"results"];
    NSLog(@"places %@",places);
    [locationView.searchedLocation reloadData];
}


- (void)saveLocation
{
    _event.location = locationView.locationField.text;
    [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)showMap
{

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
    NSLog(@"address %@",address);
    NSLog(@"cell %@",cell.detailTextLabel.text);
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [places count];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    locationView.searchedLocation.hidden = YES;
    NSDictionary *location = [[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"];
    NSString *lat = [location objectForKey:@"lat"];
    NSString *lng = [location objectForKey:@"lng"];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[lat doubleValue]
                                                            longitude:[lng doubleValue]
                                                                 zoom:6];
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(10, 128, 300, 210) camera:camera];
    mapView_.myLocationEnabled = YES;
    self.view = mapView_;
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
    marker.title = [places[indexPath.row] objectForKey:@"name"];
    marker.snippet = [places[indexPath.row] objectForKey:@"formatted_address"];
    marker.map = mapView_;
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

@end
