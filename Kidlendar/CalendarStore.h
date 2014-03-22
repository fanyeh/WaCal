//
//  CalendarStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/23.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface CalendarStore : NSObject

@property (strong,nonatomic)  EKEventStore *eventStore;
@property (strong,nonatomic)  EKCalendar *calendar;
@property (strong,nonatomic)  NSMutableArray *allCalendars;
@property (strong,nonatomic)  NSMutableDictionary *calendarSourceTitle;

+ (CalendarStore *)sharedStore;

@end
