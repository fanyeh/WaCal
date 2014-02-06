//
//  MonthCompoent.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/9.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DateModel.h"
@class EKEventStore;
@class EKCalendar;

@interface MonthModel : NSObject
@property (strong,nonatomic) NSMutableArray *datesInMonth;
@property (strong,nonatomic) NSArray *eventsInMonth;
@property (strong,nonatomic) NSArray *diarysInMonth;
@property (strong,nonatomic) NSMutableArray *eventsInDate;
@property (strong,nonatomic) NSMutableArray *diarysInDate;
@property (strong,nonatomic) NSCalendar *gregorian;

- (id)initMonthCalendarWithDate:(NSDate *)date andCalendar:(NSCalendar *)calendar;
- (BOOL)checkEventForDate:(NSDate *)date;
- (BOOL)checkDiaryForDate:(NSDate *)date;
- (int)rowNumberForDate:(NSDate *)date;
- (void)createMonthWithSelectedDate:(NSDate *)date;
- (void)fetchMonthlyEventOrDiary:(int)type;
- (DateModel *)dateModelForDate:(NSDate *)date;

@end
