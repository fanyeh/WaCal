//
//  MonthCalendarView.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DateView.h"
@class MonthModel;

@interface MonthCalendarView : UIView
@property DateView *titleLabel;
@property BOOL shrink;
@property MonthModel *monthModel;
@property (nonatomic,strong) UIView *dateGroupView;
@property CGRect shrinkFrame;

- (void)shrinkCalendarWithRow:(int)row withAnimation:(BOOL)animation complete:(void(^)(void))block;
- (void)expandCalendarWithRow:(int)row withAnimation:(BOOL)animation complete:(void(^)(void))block;
- (void)initCalendar:(MonthModel *)monthModel;
- (void)setupCalendar:(MonthModel *)monthModel;
- (void)setAppearanceOnSelectDate:(NSDate *)date;
- (void)setAppearanceOnDeselectDate:(NSDate *)date dateNotInCurrentMonth:(BOOL)inMonth;
- (DateView *)viewFromDate:(NSDate *)date;
- (void)refreshWeekday;

@end
