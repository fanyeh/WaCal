//
//  EventReviewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface EventReviewController : UIViewController
@property UIDatePicker *datePicker;
@property NSDate *selectedDate;
@property (strong ,nonatomic) EKEvent *event;
@end
