//
//  EventTitleAndTimeViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface EventTitleAndTimeViewController : UIViewController <UITextFieldDelegate>
@property NSDate *selectedDate;
@property (strong ,nonatomic) EKEvent *event;
@property (strong,nonatomic)  UIImage *backgroundImage;

@end
