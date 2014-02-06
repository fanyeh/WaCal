//
//  EventViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>


@interface EventViewController : UIViewController
@property UIDatePicker *datePicker;
@property NSDate *selectedDate;
@property (strong ,nonatomic) EKEvent *event;

@end
