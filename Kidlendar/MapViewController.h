//
//  MapViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/14.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
@class SelectedLocation;

@interface MapViewController : UIViewController
-(id)initWithLocation:(SelectedLocation *)location;

@end
