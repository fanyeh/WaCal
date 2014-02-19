//
//  EventViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventViewController.h"
#import "EventTitleAndTimeViewController.h"
#import "EventLocationViewController.h"
#import "AlarmViewController.h"
#import "RecurrenceViewController.h"
#import "GPUImage.h"
#import "CalendarStore.h"
#import "UIImage+Resize.h"
#import "ImageStore.h"
#import "LocationDataStore.h"
#import "LocationData.h"
#import <MapKit/MapKit.h>
#import "MapKitHelpers.h"

typedef void (^LocationCallback)(CLLocationCoordinate2D);

@interface EventViewController () <MKMapViewDelegate>
{
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    UIImageView *backgroundImageView;
    UIImage *blurBackgroundImage;
    GPUImageiOSBlurFilter *blurFilter;
    LocationCallback _foundLocationCallback;
    CLLocationCoordinate2D destination;
    MKPointAnnotation *previousSourceAnnotation;
    MKRoute *previousUserLocationDirectRoute;
    
    BOOL hasDestination;
}
@property (weak, nonatomic) IBOutlet UIView *eventDetailView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *alarmLabel;
@property (weak, nonatomic) IBOutlet UILabel *recurrenceLabel;
@property (weak, nonatomic) IBOutlet MKMapView *locationMapView;

@end

@implementation EventViewController

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
    
    _locationMapView.delegate = self;
    //_locationMapView.showsUserLocation = YES;
    _locationMapView.pitchEnabled = YES;
    
    // Set up background image
    backgroundImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    UIImage *image = [UIImage imageNamed:@"IMG_1725.jpg"];
    backgroundImageView.image = [image resizeImageToSize:self.view.frame.size];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    // Create blur background image
    blurFilter = [[GPUImageiOSBlurFilter alloc]init];
    blurBackgroundImage = [blurFilter imageByFilteringImage:backgroundImageView.image];

    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"MM月dd日 EEEE";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Create gestures for label
    UITapGestureRecognizer *titleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(titleChange)];
    UITapGestureRecognizer *timeTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(timeChange)];
    UITapGestureRecognizer *locationTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(locationChange)];
    UITapGestureRecognizer *alarmTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(alarmChange)];
    UITapGestureRecognizer *recurrenceTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(recurrenceChange)];
    [_titleLabel addGestureRecognizer:titleTap];
    [_timeLabel addGestureRecognizer:timeTap];
    [_locationLabel addGestureRecognizer:locationTap];
    //[_locationMapView addGestureRecognizer:locationTap];
    [_alarmLabel addGestureRecognizer:alarmTap];
    [_recurrenceLabel addGestureRecognizer:recurrenceTap];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    // Refresh label content based on event
    _titleLabel.text = _event.title;
    _dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:_event.startDate]];
    _timeLabel.text = [NSString stringWithFormat:@"%@",[timeFormatter stringFromDate:_event.startDate]];
    
    // Check if there is location
    if (_event.location) {
        _locationLabel.text = _event.location;
    }
    else {
        _locationLabel.textColor = [UIColor grayColor];
        _locationLabel.text = @"Enter location?";
    }
    
    // Check if there's event location
    NSMutableDictionary *allLocationItems = [[LocationDataStore sharedStore]allItems];
    LocationData *eventLocation = [allLocationItems objectForKey:_event.eventIdentifier];
    if (eventLocation) {
        destination =  CLLocationCoordinate2DMake(eventLocation.latitude, eventLocation.longitude);
        hasDestination = YES;
    } else {
        hasDestination = NO;
        NSLog(@"No location found for event");
    }
    
    // Check if there is alarm , if yes remove alarm button from option view
    if (_event.hasAlarms) {
        _alarmLabel.text = @"Reminder @ ";
        NSArray *alarms =  _event.alarms;
        for (EKAlarm *a in alarms) {
            int offsetMin =  (int)(a.relativeOffset*-1/60);
            _alarmLabel.text = [_alarmLabel.text stringByAppendingString:[NSString stringWithFormat:@"%d min prior",offsetMin]];
        }
    }
    else {
        _alarmLabel.textColor = [UIColor grayColor];
        _alarmLabel.text = @"Select Alarm??";
    }
    
    // Check if there is recurrence , if yes remove recurrence button from option view
    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in _event.recurrenceRules) {
            EKRecurrenceFrequency frequency = r.frequency;
            NSInteger interval = r.interval;
            switch (frequency) {
                case EKRecurrenceFrequencyDaily:
                    _recurrenceLabel.text = @"Daily";
                    break;
                case EKRecurrenceFrequencyWeekly:
                    if (interval == 1)
                        _recurrenceLabel.text = @"Weekly";

                    else
                        _recurrenceLabel.text = @"Bi-weekly";
                    break;
                case EKRecurrenceFrequencyMonthly:
                    _recurrenceLabel.text = @"Monthly";
                    break;
                case EKRecurrenceFrequencyYearly:
                    _recurrenceLabel.text = @"Yearly";
                    break;
                default:
                    break;
            }
        }
    }
    else {
        _recurrenceLabel.textColor = [UIColor grayColor];
        _recurrenceLabel.text = @"Enter Rule?";    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)deleteBtn:(id)sender
{
    NSError *err;
    if( [[[CalendarStore sharedStore]eventStore] removeEvent:_event span:EKSpanThisEvent commit:YES error:&err])
        NSLog(@"Removed");
    else
        NSLog(@"Remove fail");
    NSLog(@"Error From iCal : %@", [err description]);
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - User action on label tap to change event detail

-(void)titleChange
{
    [self pushToController:[[EventTitleAndTimeViewController alloc]init]];
}

- (void)timeChange
{
    [self pushToController:[[EventTitleAndTimeViewController alloc]init]];
}

-(void)locationChange
{
    [self pushToController:[[EventLocationViewController alloc]init]];
}

-(void)alarmChange
{
    [self pushToController:[[AlarmViewController alloc]init]];
}

-(void)recurrenceChange
{
    [self pushToController:[[RecurrenceViewController alloc]init]];
}

-(void)pushToController:(UIViewController *)vc
{
    if ([vc isKindOfClass:[EventTitleAndTimeViewController class]]) {
        ((EventTitleAndTimeViewController *)vc).selectedDate = _selectedDate;
        ((EventTitleAndTimeViewController *)vc).event = _event;
        ((EventTitleAndTimeViewController *)vc).backgroundImage = blurBackgroundImage;
    }
    else if ([vc isKindOfClass:[EventLocationViewController class]]) {
        //((EventLocationViewController *)vc).selectedDate = _selectedDate;
        ((EventLocationViewController *)vc).event = _event;
        ((EventTitleAndTimeViewController *)vc).backgroundImage = blurBackgroundImage;
    }
    else if ([vc isKindOfClass:[AlarmViewController class]]) {
        //((AlarmViewController *)vc).selectedDate = _selectedDate;
        ((AlarmViewController *)vc).event = _event;
        ((EventTitleAndTimeViewController *)vc).backgroundImage = blurBackgroundImage;
    }
    else if ([vc isKindOfClass:[RecurrenceViewController class]]) {
        //((RecurrenceViewController *)vc).selectedDate = _selectedDate;
        ((RecurrenceViewController *)vc).event = _event;
        ((EventTitleAndTimeViewController *)vc).backgroundImage = blurBackgroundImage;
    }

    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - MKMapViewDelegate

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
        }
        else {
            // Remove source annotation
            [_locationMapView removeAnnotation:previousSourceAnnotation];
            
            // Add new source annotation
            [_locationMapView addAnnotation:sourceAnnotation];
            previousSourceAnnotation = sourceAnnotation;
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {

    if (hasDestination) {
        [self calculateRouteToMapItem:userLocation.location.coordinate userDestination:(destination)];
    }
    
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
@end
