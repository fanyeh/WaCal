//
//  MonthCompoent.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/9.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "MonthModel.h"
#import "DateModel.h"
#import <EventKit/EventKit.h>
#import "DiaryDataStore.h"
#import "DiaryData.h"
#import "CalendarStore.h"
#import "KidlendarAppDelegate.h"

@implementation MonthModel
{
    NSManagedObjectContext *context;
    NSDate *currentMonthEndDate;
}

- (id)initMonthCalendarWithDate:(NSDate *)date andCalendar:(NSCalendar *)calendar
{
    self = [super init];
    if (self) {
        KidlendarAppDelegate *aDelegate = (KidlendarAppDelegate *)[[UIApplication sharedApplication] delegate];
        context = aDelegate.managedObjectContext;
        _datesInMonth = [[NSMutableArray alloc]init];
        _gregorian = calendar;
        _eventsInDate = [[NSMutableArray alloc]init];
        _eventsInMonth = [[NSMutableArray alloc]init];
        _diarysInDate = [[NSMutableArray alloc]init];
        _diarysInMonth = [[NSMutableArray alloc]init];
        [self createMonthWithSelectedDate:date];
    }
    return self;
}

- (void)createMonthWithSelectedDate:(NSDate *)date
{
    [_datesInMonth removeAllObjects];

    // Create date components based on given date and calendar
    NSDateComponents *weekdayComponents = [_gregorian components:(NSWeekdayCalendarUnit|
                                                                 NSDayCalendarUnit|
                                                                 NSMonthCalendarUnit|
                                                                 NSYearCalendarUnit
                                                                 )
                                                       fromDate:date];
    // Normalize _selectedDate
    NSDate *sd = [_gregorian dateFromComponents:weekdayComponents];
    
    // Get number of days of given month
    NSRange days = [_gregorian rangeOfUnit:NSDayCalendarUnit
                                   inUnit:NSMonthCalendarUnit
                                  forDate:[_gregorian dateFromComponents:weekdayComponents]];
    
    // Get first day of the month
    weekdayComponents.day = 1;
    NSDate *w = [_gregorian dateFromComponents:weekdayComponents];
    NSDateComponents *comp = [_gregorian components:NSWeekdayCalendarUnit
                                          fromDate:w];
    
    // Monday = 1 , Sunday = 7
    long weekDayOfFirstDay = [comp weekday]-1;
    if (weekDayOfFirstDay==0)
        weekDayOfFirstDay = 7;
    
    // Initial row number for each date view
    int rowNum = 0;
    
    // Draw prevoius month date in same week
    long previousMonthDays = weekDayOfFirstDay - 1;
    weekdayComponents.day -= previousMonthDays;
    DateModel *newDateModel;

    if (weekDayOfFirstDay!=1) {
        // Create DateComponent
        if (previousMonthDays > 0) {
            for (int i =0 ; i < previousMonthDays; i++) {
                NSDate *p = [_gregorian dateFromComponents:weekdayComponents];
                newDateModel = [[DateModel alloc]initWithDate:p rowNumber:rowNum];
                [_datesInMonth addObject:newDateModel];
                weekdayComponents.day += 1;
            }
        }
    }
    else {
        rowNum = -1;
    }
    
    // Normalize today's date
    NSDate *td = [NSDate date];
    comp = [_gregorian components:(NSWeekdayCalendarUnit|
                                  NSDayCalendarUnit|
                                  NSMonthCalendarUnit|
                                  NSYearCalendarUnit)
                        fromDate:td];
    td = [_gregorian dateFromComponents:comp];
    
    // Draw the calendar
    for(int i=1;i<days.length+1;i++) {
        weekdayComponents.day = i;
        NSDate *c = [_gregorian dateFromComponents:weekdayComponents];
        
        // Change to next row after if week day is monday
        if (weekDayOfFirstDay==1)
            rowNum++;
        
        if (weekDayOfFirstDay==7)
            weekDayOfFirstDay = 1;
        else
            weekDayOfFirstDay++;
        
        // Check if there event in this day
        newDateModel = [[DateModel alloc]initWithDate:c rowNumber:rowNum];
        newDateModel.isCurrentMonth = YES;
        
        if (i==1 && [comp month] != [weekdayComponents month])
            newDateModel.isFirstDay = YES;
        if (td==c)
            newDateModel.isToday = YES;
        if (sd==c)
            newDateModel.isSelected = YES;
        [_datesInMonth addObject:newDateModel];
    }
    
    // Draw next month date in same week
    int compensateDaysForNextMonth = 7;
    if (rowNum == 4 && weekDayOfFirstDay !=1)
        compensateDaysForNextMonth = 14;
    long nextMonthDays = compensateDaysForNextMonth- (weekDayOfFirstDay -1);
    if (nextMonthDays == 7)
        rowNum++;
    long rowChange = 7 - weekDayOfFirstDay;

    if (nextMonthDays > 0) {
        for (int i =0 ; i < nextMonthDays; i++) {
            weekdayComponents.day += 1;
            NSDate *p = [_gregorian dateFromComponents:weekdayComponents];
            newDateModel = [[DateModel alloc]initWithDate:p rowNumber:rowNum];
            [_datesInMonth addObject:newDateModel];
            if (i == rowChange)
                rowNum++;
        }
    }
    [self fetchMonthlyEventOrDiary:0];
    [self fetchMonthlyEventOrDiary:1];
    
    for (DateModel *model in _datesInMonth) {
        model.hasEvent = [self checkEventForDate:model.date];
        model.hasDiary = [self checkDiaryForDate:model.date];
    }
    
    weekdayComponents.day +=1;
    currentMonthEndDate = [_gregorian dateFromComponents:weekdayComponents];
}

- (void)fetchMonthlyEventOrDiary:(int)type
{
    NSDate *startDate = ((DateModel *)_datesInMonth[0]).date;
    // End date is start of end date + 1 day
    NSDate *endDate = ((DateModel *)[_datesInMonth lastObject]).date;
    
    NSDateComponents *comp = [_gregorian components:(NSWeekdayCalendarUnit|
                                   NSDayCalendarUnit|
                                   NSMonthCalendarUnit|
                                   NSYearCalendarUnit)
                         fromDate:endDate];
    
    comp.day += 1;

    endDate = [_gregorian dateFromComponents:comp];


    // Type 0 = Event , 1 = Diary
    if (type==0) {
        if ([[CalendarStore sharedStore]selectedCalendars].count > 0 ) {
            NSPredicate *predicate = [[[CalendarStore sharedStore]eventStore] predicateForEventsWithStartDate:startDate
                                                                                                      endDate:endDate
                                                                                                    calendars:[[CalendarStore sharedStore]selectedCalendars]];
            
            NSArray *events = [[[CalendarStore sharedStore]eventStore] eventsMatchingPredicate:predicate];
            _eventsInMonth = events;
        } else
            _eventsInMonth = nil;
    }
    else {
        
        NSMutableArray *fetchedDiary = [[NSMutableArray alloc]init];
        for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
            if (d.dateCreated > [startDate timeIntervalSinceReferenceDate] && d.dateCreated < [endDate timeIntervalSinceReferenceDate]) {
                [fetchedDiary addObject:d];
            }
        }
        _diarysInMonth =fetchedDiary;
    }
}

- (BOOL)checkEventForDate:(NSDate *)date
{
    [_eventsInDate removeAllObjects];
    NSDateComponents *dateComp = [_gregorian components:(NSCalendarUnitDay|
                                                        NSCalendarUnitMonth|
                                                        NSCalendarUnitYear)
                                              fromDate:date];
    for (EKEvent *e in _eventsInMonth) {
        
        NSDateComponents *eventComp = [_gregorian components:(NSCalendarUnitDay|
                                                             NSCalendarUnitMonth|
                                                             NSCalendarUnitYear)
                                                   fromDate:e.startDate];
        
        if ([eventComp day] == [dateComp day] && [eventComp month] ==[dateComp month] && [eventComp year] == [dateComp year])
            [_eventsInDate addObject:e];
    }
    if ([_eventsInDate count]> 0)
        return YES;
    else
        return NO;
}

- (BOOL)checkDiaryForDate:(NSDate *)date
{
    [_diarysInDate removeAllObjects];
    NSDateComponents *dateComp = [_gregorian components:(NSCalendarUnitDay|
                                                        NSCalendarUnitMonth|
                                                        NSCalendarUnitYear)
                                              fromDate:date];
    for (DiaryData *d in _diarysInMonth) {
        NSDateComponents *diaryComp = [_gregorian components:(NSCalendarUnitDay|
                                                             NSCalendarUnitMonth|
                                                             NSCalendarUnitYear)
                                                   fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated]];
        
        if ([diaryComp day] == [dateComp day] && [diaryComp month] ==[dateComp month] && [diaryComp year] == [dateComp year]) {
            [_diarysInDate addObject:d];
        }
    }
    if ([_diarysInDate count]> 0)
        return  YES;
    else
        return NO;
}

- (int)rowNumberForDate:(NSDate *)date
{
    NSDateComponents *dateComp = [_gregorian components:(NSCalendarUnitDay|
                                                        NSCalendarUnitMonth|
                                                        NSCalendarUnitYear)
                                              fromDate:date];
    NSDate *requestDate = [_gregorian dateFromComponents:dateComp];
    for (DateModel *d in _datesInMonth) {
        if ([d.date isEqual:requestDate])
            return d.row;
    }
    return 0;
}

- (DateModel *)dateModelForDate:(NSDate *)date
{
    NSDateComponents *dateComp = [_gregorian components:(NSCalendarUnitDay|
                                                         NSCalendarUnitMonth|
                                                         NSCalendarUnitYear)
                                               fromDate:date];
    NSDate *requestDate = [_gregorian dateFromComponents:dateComp];
    for (DateModel *d in _datesInMonth) {
        if ([d.date isEqual:requestDate])
            return d;
    }
    return nil;
}

@end
