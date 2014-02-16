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
#import "ImageStore.h"
#import <MapKit/MapKit.h>

typedef void (^LocationCallback)(CLLocationCoordinate2D);

@interface EventLocationViewController () <MKMapViewDelegate>
{
    CGRect titleViewFrameShow;
    EventLocationView *locationView;
    UIImageView *backgroundImageView;
    MKMapView *mapView_;
    CLGeocoder *geocoder;
    NSArray* places;
    UIActivityIndicatorView *activityIndicator;
    LocationCallback _foundLocationCallback;
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
    
    // Table view to show searched locations
    locationView.searchedLocationTable.dataSource = self;
    locationView.searchedLocationTable.delegate = self;
    //[locationView.searchedLocation registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    activityIndicator = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    [activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicator.center = CGPointMake(self.view.center.x, self.view.center.y - 30);
    [self.view addSubview:activityIndicator];
    [activityIndicator stopAnimating];
    
    mapView_ = [[MKMapView alloc]initWithFrame:CGRectMake(10, 128, 300, 210)];
    mapView_.pitchEnabled = YES;
    mapView_.showsUserLocation = YES;
    mapView_.hidden = YES;
    mapView_.delegate = self;
    [self.view addSubview:mapView_];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clearText)];
    [locationView.locationField.rightView addGestureRecognizer:tapGesture];
    
    // Put save button on navigation bar
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(saveLocation)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)startSearchForText:(NSString*)searchText
{
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchText;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        if (response.mapItems.count > 0) {
            places = [response.mapItems copy];
            [locationView.searchedLocationTable reloadData];
            locationView.searchedLocationTable.hidden = NO;

        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"No search results found! Try again with a different query."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
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
    MKMapItem *mapItem = [places objectAtIndex:indexPath.row];
    NSString *locName = [mapItem.placemark.addressDictionary objectForKey:@"Name"];
    cell.textLabel.text = locName;

    //NSString *address = [places[indexPath.row] objectForKey:@"formatted_address"];
    //cell.detailTextLabel.text = address;
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
    MKMapItem *item = [places objectAtIndex:indexPath.row];
    [self calculateRouteToMapItem:item];
    locationView.locationField.text = [item.placemark.addressDictionary objectForKey:@"Name"];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self startSearchForText:locationView.locationField.text];
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

- (MKMapItem*)mapItemForCoordinate:(CLLocationCoordinate2D)coordinate {
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    return mapItem;
}

- (void)calculateRouteToMapItem:(MKMapItem*)item {
    // 1
    [self performAfterFindingLocation:^(CLLocationCoordinate2D userLocation) {
        // 2
        MKPointAnnotation *sourceAnnotation = [MKPointAnnotation new];
        sourceAnnotation.coordinate = userLocation;
        sourceAnnotation.title = @"Start";
        
        MKPointAnnotation *destinationAnnotation = [MKPointAnnotation new];
        destinationAnnotation.coordinate = item.placemark.coordinate;
        destinationAnnotation.title = @"End";
        
        __block MKRoute *fromUserLocationDirectionsRoute = nil;

        // 1
        MKMapItem *sourceMapItem = [self mapItemForCoordinate:userLocation];
        MKMapItem *destinationMapItem = item;
        
        // 3
        dispatch_group_t group = dispatch_group_create();
        
        // 4
        // Find route to source airport
        dispatch_group_enter(group);
        [self obtainDirectionsFrom:sourceMapItem
                                to:destinationMapItem
                        completion:^(MKRoute *route, NSError *error) {
                            fromUserLocationDirectionsRoute = route;
                            dispatch_group_leave(group);
                        }];
        
        // 6
        // When both are found, setup new route
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            
                [mapView_ addAnnotations:@[sourceAnnotation, destinationAnnotation]];
            
                [mapView_ addOverlay:fromUserLocationDirectionsRoute.polyline level:MKOverlayLevelAboveRoads];
            
                MKMapPoint points[2];
                points[0] = MKMapPointForCoordinate(sourceAnnotation.coordinate);
                points[1] = MKMapPointForCoordinate(destinationAnnotation.coordinate);
                
                MKCoordinateRegion boundingRegion = CoordinateRegionBoundingMapPoints(points, 2);
                boundingRegion.span.latitudeDelta *= 1.1f;
                boundingRegion.span.longitudeDelta *= 1.1f;
                [mapView_ setRegion:boundingRegion animated:YES];
        });
    }];
}

- (void)obtainDirectionsFrom:(MKMapItem*)from to:(MKMapItem*)to completion:(void(^)(MKRoute *route, NSError *error))completion {
    // 1
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
    // 2
    request.source = from;
    request.destination = to;
    
    // 3
    request.transportType = MKDirectionsTransportTypeAutomobile;
    
    // 4
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = nil;
        
        // 5
        if (response.routes.count > 0) {
            route = response.routes[0];
        } else if (!error) {
            error = [NSError errorWithDomain:@"com.razeware.FlyMeThere" code:404 userInfo:@{NSLocalizedDescriptionKey:@"No routes found!"}];
        }
        
        // 6
        if (completion) {
            completion(route, error);
        }
    }];
}

- (void)performAfterFindingLocation:(LocationCallback)callback {
    if (mapView_.userLocation != nil) {
        if (callback) {
            callback(mapView_.userLocation.coordinate);
        }
    } else {
        _foundLocationCallback = [callback copy];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (_foundLocationCallback) {
        _foundLocationCallback(userLocation.coordinate);
        _foundLocationCallback = nil;
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKPlacemark class]]) {
        MKPinAnnotationView *pin = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"placemark"];
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"placemark"];
            pin.pinColor = MKPinAnnotationColorRed;
            pin.canShowCallout = YES;
        } else {
            pin.annotation = annotation;
        }
        return pin;
    }
    return nil;
}

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    NSLog(@"Renderer %@",overlay);

    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
        renderer.strokeColor = [UIColor blueColor];
        return renderer;
    }
    return nil;
}


MKCoordinateRegion CoordinateRegionBoundingMapPoints(MKMapPoint *points, NSUInteger count) {
    if (count == 0) {
        return MKCoordinateRegionForMapRect(MKMapRectWorld);
    }
    
    MKMapRect boundingMapRect;
    boundingMapRect.origin = points[0];
    boundingMapRect.size = MKMapSizeMake(0.0, 0.0);
    
    for (NSUInteger i = 1; i < count; i++) {
        MKMapPoint point = points[i];
        if (!MKMapRectContainsPoint(boundingMapRect, point)) {
            boundingMapRect = MKMapRectUnion(boundingMapRect, (MKMapRect){.origin=point,.size={0.0,0.0}});
        }
    }
    
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(boundingMapRect);
    region.span.latitudeDelta = MAX(region.span.latitudeDelta, 0.001);
    region.span.longitudeDelta = MAX(region.span.longitudeDelta, 0.001);
    
    return region;
}

@end
