//
//  MonthViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MonthCalendarView.h"
#import <EventKit/EventKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MonthViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property (strong, nonatomic) IBOutlet MonthCalendarView *monthView;
@property NSCalendar *gregorian;
@property NSDate *selectedDate;


@end
