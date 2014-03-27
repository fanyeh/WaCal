//
//  MonthCalendarView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "MonthCalendarView.h"
#import <EventKit/EventKit.h>
#import "MonthModel.h"
#import "DateModel.h"
#import "WeekdayView.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
#define MainColor [UIColor colorWithRed:(64 / 255.0) green:(98 / 255.0) blue:(124 / 255.0) alpha:1.0]
#define TodayColor [UIColor colorWithRed:(217 / 255.0) green:(100 / 255.0) blue:(89 / 255.0) alpha:1.0]


@implementation MonthCalendarView
{
    CGFloat dateViewWidth;
    CGFloat dateViewHeight;
    CGFloat weekdayComponentHeight;
    CGRect monthViewFrame;
    CGFloat calendarWidth;
    CGFloat calendarHeight;
    CGFloat weekdayViewHeight;
    NSMutableArray *weekdayArray;
    CGRect dateGroupFrame;
    DateView *fadeDateView;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _shrink =NO;
    }
    return self;
}

- (void)initCalendar:(MonthModel *)monthModel
{
    // Initialization code
    _monthModel = monthModel;
    CGFloat xOffSet = 0.0f;
    CGFloat yOffSet = 0.0f;
    calendarWidth = self.frame.size.width;
    calendarHeight = self.frame.size.height - weekdayViewHeight;
    
    dateViewWidth = calendarWidth/7;
    dateViewHeight = calendarHeight/7;
    weekdayViewHeight = 40;
    
    _dateGroupView = [[UIView alloc]initWithFrame:CGRectMake(0, weekdayViewHeight, calendarWidth,calendarHeight-  weekdayViewHeight+1)];
    _dateGroupView.backgroundColor = [UIColor clearColor];
    
    dateGroupFrame = _dateGroupView.frame;

    [self addSubview:_dateGroupView];
    
    NSArray *weekDay = @[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"];
    weekdayArray = [[NSMutableArray alloc]init];
    
    // Set weekdays
    for (int i=1;i<8;i++) {
        WeekdayView *dateView = [[WeekdayView alloc]initWithFrame:CGRectMake(xOffSet,yOffSet,dateViewWidth,weekdayViewHeight)];
        [dateView.dateLabel setText:weekDay[i-1]];
        dateView.dateLabel.frame = CGRectMake(0,0, dateViewWidth, weekdayViewHeight);
        xOffSet += dateViewWidth;
        dateView.row = -1;
        [weekdayArray addObject:dateView];
        [self addSubview:dateView];
    }
    monthViewFrame = self.frame;

    _shrinkFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, weekdayViewHeight + dateViewHeight);
    // Init date labels

    [self setupCalendar:_monthModel];
}

- (void)setupCalendar:(MonthModel *)monthModel
{
    self.frame = monthViewFrame;
    _dateGroupView.frame = dateGroupFrame;
    
    for (DateView *subview in _dateGroupView.subviews) {
        [subview removeFromSuperview];
    }
    _monthModel = monthModel;
    
    // Define x , y offset for date view
    CGFloat xOffSet = 0;
    CGFloat yOffSet = 0;

    NSArray *datesInMonth  = _monthModel.datesInMonth;
    NSDateComponents *dateComp;
    DateModel *dateModel;
    
    // Draw the calendar
    for(int i=0;i<[datesInMonth count];i++) {
        dateModel = datesInMonth[i];
        dateComp = [[NSCalendar currentCalendar]components:NSDayCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit fromDate:dateModel.date];
        
        // Init date view
        DateView *dateView = [[DateView alloc]initWithFrame:CGRectMake(xOffSet, yOffSet, dateViewWidth, dateViewHeight)];
        [_dateGroupView addSubview:dateView];


        dateView.row = dateModel.row;
        dateView.tag = i; // Index to link view and date model
        dateView.date = dateModel.date;
        [dateView.dateLabel setText:[NSString stringWithFormat:@"%ld",(long)dateComp.day]];
        
        // Configure color for dates not in current month
        if (dateModel.isCurrentMonth)
            dateView.dateLabel.textColor = [UIColor colorWithWhite:0.502 alpha:1.000];
        else
            dateView.dateLabel.textColor = [UIColor colorWithWhite:0.902 alpha:1.000];
        
        // Configure color for today
        if (dateModel.isToday) {
            dateView.isToday = YES;
            dateView.dateLabel.textColor = TodayColor;
        }
        
        // Add indicator if date has event
        if (dateModel.hasEvent)
            [dateView addHasEventView];
        
        // Add indicator if date has diary
        if (dateModel.hasDiary)
            [dateView addHasDiaryView];

        // Switch date view Y position for week change
        if (i%7 == 6) {
            yOffSet += dateViewHeight;
            xOffSet = 0;
        } else {
            xOffSet += dateViewWidth;
        }
        
        dateView.column = i%7;
    }
}

- (void)shrinkCalendarWithRow:(int)row withAnimation:(BOOL)animation complete:(void(^)(void))block
{
    __block CGFloat shiftOffset = row * dateViewHeight;
    __block CGFloat shrinkOffset = (5-row) * dateViewHeight;

    if (animation) {
        
        [UIView animateWithDuration:0.4f animations:^{
            // 1. Shift original frame
            _dateGroupView.frame = CGRectOffset(dateGroupFrame, 0, -shiftOffset);
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4f animations:^{
                
                // 2. Shrink shifted frame
                _dateGroupView.frame = CGRectMake(_dateGroupView.frame.origin.x,
                                                  _dateGroupView.frame.origin.y,
                                                  _dateGroupView.frame.size.width,
                                                  _dateGroupView.frame.size.height - shrinkOffset);
                
                // 3. Invis dates not in selected row
                for (DateView *view in _dateGroupView.subviews) {
                    if (view.row != row && view.row > -1) {
                        view.alpha = 0;
                    }
                }
            } completion:^(BOOL finished) {
                block();
            }];
        }];
        
    } else {
        // 1. Shift & Shrinkframe
        _dateGroupView.frame = CGRectMake(_dateGroupView.frame.origin.x,
                                          _dateGroupView.frame.origin.y-shiftOffset,
                                          _dateGroupView.frame.size.width,
                                          _dateGroupView.frame.size.height - shrinkOffset);

        // 2. Invis dates not in selected row
        for (DateView *view in _dateGroupView.subviews) {
            if (view.row != row && view.row > -1) {
                view.alpha = 0;
            }
        }
        block();
    }
    self.frame = _shrinkFrame;
    _shrink = YES;
}

- (void)expandCalendarWithRow:(int)row withAnimation:(BOOL)animation complete:(void(^)(void))block
{
    __block CGFloat shiftOffset = row * dateViewHeight;
    __block CGFloat expandOffset = (5-row) * dateViewHeight;
    
    if (animation) {
        [UIView animateWithDuration:0.4f animations:^{
            // 1. un invis dates
            for (DateView *view in _dateGroupView.subviews) {
                if (view.row < row ) {
                    view.alpha = 1;
                }
            }
            
            // 2. Shift current frame to original poistion
            _dateGroupView.frame = CGRectOffset(_dateGroupView.frame, 0, shiftOffset);
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4f animations:^{
                
                // 3. Unhide bottom dates
                for (DateView *view in _dateGroupView.subviews) {
                    if (view.row > row ) {
                        view.alpha = 1;
                    }
                }
                
                // 5. Expand frame
                _dateGroupView.frame = CGRectMake(_dateGroupView.frame.origin.x,
                                                  _dateGroupView.frame.origin.y,
                                                  _dateGroupView.frame.size.width,
                                                  _dateGroupView.frame.size.height + expandOffset);
            } completion:^(BOOL finished) {
                block();
            }];
        }];

    } else {
        // 1. Shift & Expand frame
        _dateGroupView.frame = CGRectMake(_dateGroupView.frame.origin.x,
                                          _dateGroupView.frame.origin.y+shiftOffset,
                                          _dateGroupView.frame.size.width,
                                          _dateGroupView.frame.size.height + expandOffset);
        
        // 2. Unhide dates not in selected row
        for (DateView *view in _dateGroupView.subviews) {
            if (view.row != row && view.row > -1) {
                view.alpha = 1;
            }
        }
        block();
    }
    self.frame = monthViewFrame;
    self.shrink = NO;
}

- (void)setAppearanceOnSelectDate:(NSDate *)date
{
    DateView *view =[self viewFromDate:date];
    WeekdayView *weekdayView = weekdayArray[view.column];
    weekdayView.selectedLabel.hidden = NO;
    view.dateLabel.layer.cornerRadius = view.dateLabel.frame.size.width/2;

    CATransition *animation = [CATransition animation];
    animation.duration = 0.3f;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [view.dateLabel.layer addAnimation:animation forKey:nil];
    [weekdayView.selectedLabel.layer addAnimation:animation forKey:nil];

    if (view.isToday) {
        view.dateLabel.backgroundColor = TodayColor;
        weekdayView.selectedLabel.backgroundColor = TodayColor;
    }
    else {
        view.dateLabel.backgroundColor = MainColor;
        weekdayView.selectedLabel.backgroundColor = MainColor;
    }
    
    view.dateLabel.textColor = [UIColor whiteColor];
    view.isSelected = YES;
}

- (void)setAppearanceOnDeselectDate:(NSDate *)date dateNotInCurrentMonth:(BOOL)inMonth
{
    DateView *view =[self viewFromDate:date];
    view.isSelected = NO;
    WeekdayView *weekdayView = weekdayArray[view.column];
    fadeDateView = view;
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3f;
    animation.delegate = self;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [view.dateLabel.layer addAnimation:animation forKey:nil];
    view.dateLabel.backgroundColor =[UIColor clearColor];
    if (view.isToday) {
        view.dateLabel.textColor = TodayColor;
    }
    else
        view.dateLabel.textColor = [UIColor colorWithWhite:0.600 alpha:1.000];
    
    CATransition *fadeWeekday = [CATransition animation];
    fadeWeekday.duration = 0.3f;
    fadeWeekday.type = kCATransitionFade;
    fadeWeekday.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [weekdayView.selectedLabel.layer addAnimation:fadeWeekday forKey:nil];
    weekdayView.selectedLabel.hidden = YES;
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    fadeDateView.dateLabel.layer.cornerRadius = 0.0f;
}

- (DateView *)viewFromDate:(NSDate *)date
{
    for (DateView *d in _dateGroupView.subviews) {
        if (d.date==date)
            return d;
    }
    return nil;
}

@end
