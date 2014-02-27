//
//  EventCreateController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>


@interface EventCreateController : UIViewController
@property UIDatePicker *datePicker;
@property NSDate *selectedDate;

@end
