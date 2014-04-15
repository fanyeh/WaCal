//
//  CalendarStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/23.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

extern NSString *const RemindersModelChangedNotification;
extern NSString *const EventsAccessGranted;
extern NSString *const RemindersAccessGranted;

@interface CalendarStore : NSObject

@property (strong,nonatomic)  EKEventStore *eventStore;
//@property (strong,nonatomic)  EKCalendar *calendar;
@property (strong,nonatomic)  NSMutableArray *allCalendars;
@property (strong,nonatomic)  NSMutableArray *selectedCalendars;
@property (strong,nonatomic)  NSMutableDictionary *calendarSourceTitle;
@property (strong,nonatomic)  NSMutableArray *selectedCalIDs;
@property (strong,nonatomic) NSMutableDictionary *calendarDict;
@property (assign, readonly) BOOL eventAccess;
@property (assign, readonly) BOOL reminderAccess;
@property (strong) NSMutableArray *reminders;

+ (CalendarStore *)sharedStore;
- (void)setSelectedCalendarsByIDs;
- (void)setSelectedIDsByCalendars;
- (void)setCalendars;


@end
