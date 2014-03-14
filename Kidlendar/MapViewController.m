//
//  MapViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/14.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "MapViewController.h"
#import "MapKitHelpers.h"
#import <MapKit/MapKit.h>

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"

@interface MapViewController () <MKMapViewDelegate>
{
    CLLocationCoordinate2D destination;
    MKPointAnnotation *previousSourceAnnotation;
    MKPointAnnotation *previousDestinationAnnotation;
    MKRoute *previousUserLocationDirectRoute;
    NSString *destinationReference;
}
@property (weak, nonatomic) IBOutlet MKMapView *locationMapView;
@property (weak, nonatomic) IBOutlet UIView *mapDetailView;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@end

@implementation MapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithLocation:(NSDictionary *)location
{
    self = [super init];
    if (self) {
        double lat =  [[[[location objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
        double lon = [[[[location objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
        _locationNameLabel.text = [location objectForKey:@"name"];
        _addressLabel.text = [location objectForKey:@"formatted_address"];
        destinationReference = [location objectForKey:@"reference"];
        destination = CLLocationCoordinate2DMake(lat, lon);
    }
    return  self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _locationMapView.delegate = self;
    _locationMapView.userTrackingMode = MKMapTypeStandard;
    UITapGestureRecognizer *phoneTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(makeCall)];
    [_phoneNumberLabel addGestureRecognizer:phoneTap];
//    [self calculateRouteToMapItem:_locationMapView.userLocation.location.coordinate userDestination:destination];
    [self queryGooglePlaceDetails:destinationReference];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - Put Route on Map

- (MKMapItem*)mapItemForCoordinate:(CLLocationCoordinate2D)coordinate {
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    return mapItem;
}

- (void)calculateRouteToMapItem:(CLLocationCoordinate2D)userLocation userDestination:(CLLocationCoordinate2D)userDestination
{
    // 2
    MKPointAnnotation *sourceAnnotation = [MKPointAnnotation new];
    sourceAnnotation.coordinate = userLocation;
    sourceAnnotation.title = @"Start";
    
    MKPointAnnotation *destinationAnnotation = [MKPointAnnotation new];
    destinationAnnotation.coordinate = userDestination;
    destinationAnnotation.title = @"End";
    
    __block MKRoute *fromUserLocationDirectionsRoute = nil;
    
    // 1
    MKMapItem *sourceMapItem = [self mapItemForCoordinate:userLocation];
    MKMapItem *destinationMapItem = [self mapItemForCoordinate:userDestination];;
    
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
        
        // Add source/dest annotation
        if ([_locationMapView.annotations count]==1) {
            [_locationMapView addAnnotations:@[destinationAnnotation,sourceAnnotation]];
            previousSourceAnnotation = sourceAnnotation;
            previousDestinationAnnotation = destinationAnnotation;
        }
        // Remove then add source/desitination for latest location updates for route
        else {
            // Remove source annotation
            [_locationMapView removeAnnotation:previousSourceAnnotation];
            [_locationMapView removeAnnotation:previousDestinationAnnotation];
            
            // Add new source annotation
            [_locationMapView addAnnotation:sourceAnnotation];
            [_locationMapView addAnnotation:destinationAnnotation];
            
            previousSourceAnnotation = sourceAnnotation;
            previousDestinationAnnotation = destinationAnnotation;
            
            [_locationMapView removeOverlay:previousUserLocationDirectRoute.polyline];
        }
        
        // Add route overlay
        [_locationMapView addOverlay:fromUserLocationDirectionsRoute.polyline level:MKOverlayLevelAboveRoads];
        previousUserLocationDirectRoute = fromUserLocationDirectionsRoute;
        
        MKMapPoint points[2];
        points[0] = MKMapPointForCoordinate(sourceAnnotation.coordinate);
        points[1] = MKMapPointForCoordinate(destinationAnnotation.coordinate);
        
        MKCoordinateRegion boundingRegion = CoordinateRegionBoundingMapPoints(points, 2);
        boundingRegion.span.latitudeDelta *= 1.1f;
        boundingRegion.span.longitudeDelta *= 1.1f;
        [_locationMapView setRegion:boundingRegion animated:YES];
        CLLocation *destinationLocation = [[CLLocation alloc]initWithLatitude:destination.latitude longitude:destination.longitude];
        
        _distanceLabel.text = [NSString stringWithFormat:@"%.1f KM",[_locationMapView.userLocation.location distanceFromLocation:destinationLocation]/1000];
    });
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

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self calculateRouteToMapItem:userLocation.location.coordinate userDestination:(destination)];
}

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

- (MKOverlayRenderer*)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay];
        renderer.strokeColor = [UIColor blueColor];
        return renderer;
    }
    return nil;
}

#pragma mark - Google Search

-(void)queryGooglePlaceDetails:(NSString *)reference
{
    // Sensor = true means search using GPS
    NSString *url;
    url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&sensor=true&key=%@",reference,kGOOGLE_API_KEY];
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
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       _locationNameLabel.text = [[json objectForKey:@"result"] objectForKey:@"name"];
                                       _addressLabel.text = [[json objectForKey:@"result"] objectForKey:@"formatted_address"];
                                       _phoneNumberLabel.text = [[json objectForKey:@"result"] objectForKey:@"formatted_phone_number"];
                                   });
                                   
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}

- (void)makeCall
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel:%@",[_phoneNumberLabel.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
