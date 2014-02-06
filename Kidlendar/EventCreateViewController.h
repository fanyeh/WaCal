//
//  EventCreateViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface EventCreateViewController : UIViewController <UITextFieldDelegate>
@property UIDatePicker *datePicker;
@property NSDate *selectedDate;
@end
