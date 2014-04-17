//
//  MapViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/14.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"

@class SelectedLocation;

@interface MapViewController : UIViewController
-(id)initWithLocation:(SelectedLocation *)location;

@end
