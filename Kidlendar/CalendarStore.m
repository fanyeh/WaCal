//
//  CalendarStore.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/23.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "CalendarStore.h"

#define kRemindersCalendarTitle @"W&Cal"

NSString *const RemindersModelChangedNotification = @"RemindersModelChangedNotification";
NSString *const EventsAccessGranted = @"EventsAccessGranted";
NSString *const RemindersAccessGranted = @"RemindersAccessGranted";

@implementation CalendarStore
+ (CalendarStore *)sharedStore
{
    static CalendarStore *sharedStore = nil;
    if(!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if(self) {
        self.eventStore = [[EKEventStore alloc]init];
        _selectedCalendars = [[NSMutableArray alloc]init];
        _selectedCalIDs = [[NSMutableArray alloc]init];

    }
    return self;
}


#pragma mark - Event

- (void)setSelectedCalendarsByIDs
{
    for (EKCalendar *c in _allCalendars) {
        for (NSString *identifier in _selectedCalIDs) {
            if ([identifier isEqualToString:c.calendarIdentifier]) {
                [_selectedCalendars addObject:c];
            }
        }
    }
}
- (void)setCalendars
{
    _allCalendars = [[NSMutableArray alloc]initWithArray:[[[CalendarStore sharedStore]eventStore] calendarsForEntityType:EKEntityTypeEvent]];
    [self calendarKeys];
}

-(void)setSelectedIDsByCalendars
{
    for (EKCalendar *c in [[CalendarStore sharedStore]allCalendars]) {
        [_selectedCalIDs addObject:c.calendarIdentifier];
    }
    [self setSelectedCalendarsByIDs];
}

-(void)calendarKeys
{
    NSMutableArray *keys = [[NSMutableArray alloc]init];
    _calendarDict = [[NSMutableDictionary alloc]init];

    for (EKCalendar *cal in _allCalendars) {
        
        NSString *sourceTitle;
        if (!cal.allowsContentModifications)
            sourceTitle = @"Other";
        else
            sourceTitle = cal.source.title;
        
        if ([keys indexOfObject:sourceTitle] == NSNotFound) {
            [keys addObject:cal.source.title];
            [_calendarDict setObject:[[NSMutableArray alloc]init] forKey:cal.source.title];
        }
    }
    
    for (EKCalendar *cal in _allCalendars) {
        
        NSString *sourceTitle;
        if (!cal.allowsContentModifications)
            sourceTitle = @"Other";
        else
            sourceTitle = cal.source.title;
        
        NSMutableArray *calendars = [_calendarDict objectForKey:sourceTitle];
        [calendars addObject:cal];
    }
}

//#pragma mark - Reminder
//
//- (EKCalendar*) calendarForReminders {
//    
//    //1
//    for (EKCalendar *calendar in [self.eventStore calendarsForEntityType:EKEntityTypeReminder]) {
//        if ([calendar.title isEqualToString:kRemindersCalendarTitle]) {
//            return calendar;
//        }
//    }
//    
//    //2
//    EKCalendar *remindersCalendar =  [EKCalendar calendarForEntityType:EKEntityTypeReminder eventStore:self.eventStore];
//    remindersCalendar.title = kRemindersCalendarTitle;
//    remindersCalendar.source = self.eventStore.defaultCalendarForNewReminders.source;
//    
//    NSError *err;
//    BOOL success = [self.eventStore saveCalendar:remindersCalendar commit:YES error:&err];
//    if (!success) {
//        NSLog(@"There was an error creating the reminders calendar");
//        return nil;
//    }
//    return remindersCalendar;
//}
//
//
//- (void) fetchAllConferenceReminders {
//    //1
//    NSPredicate *predicate = [_eventStore predicateForRemindersInCalendars:@[[self calendarForReminders]]];
//    
//    //2
//    [_eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders){
//        
//         _reminders = [reminders mutableCopy];
////         [[NSNotificationCenter defaultCenter]postNotificationName:RemindersModelChangedNotification object:self];
//        
//     }];
//}
//
//- (void) reminder:(EKReminder*) reminder setCompletionFlagTo:(BOOL) completionFlag {
//    
//    //1. Set the completed flag
//    //Note: The completion date is automatically
//    //      set to the current date
//    
//    reminder.completed = completionFlag;
//    
//    //2
//    NSError *err;
//    BOOL success = [self.eventStore saveReminder:reminder commit:YES error:&err];
//    if (!success) {
//        NSLog(@"There was an error editing the reminder");
//    }
//}
//
//- (void) addReminderWithTitle:(NSString*) title
//                      dueTime:(NSDate*) dueDate {
//    
//    if (!_reminderAccess) {
//        NSLog(@"No reminder acccess!");
//        return;
//    }
//    
//    //1.Create a reminder
//    EKReminder *reminder = [EKReminder reminderWithEventStore:self.eventStore];
//    
//    //2. Set the title
//    reminder.title = title;
//    
//    //3. Set the calendar
//    reminder.calendar = [self calendarForReminders];
//    
//    //4. Extract the NSDateComponents from the dueDate
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    
//    NSUInteger unitFlags = NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
//    
//    NSDateComponents *dueDateComponents = [calendar components:unitFlags fromDate:dueDate];
//    
//    //5. Set the due date
//    reminder.dueDateComponents = dueDateComponents;
//    
//    //6. Save the reminder
//    NSError *err;
//    BOOL success = [self.eventStore saveReminder:reminder commit:YES error:&err];
//    
//    if (!success) {
//        NSLog(@"There was an error saving the reminder %@",
//              err);
//    }
//}

@end
