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

@implementation MonthCalendarView
{
    CGFloat dateViewWidth;
    CGFloat dateViewHeight;
    CGFloat weekdayComponentHeight;
    CGRect monthViewFrame;
    CGFloat calendarWidth;
    CGFloat calendarHeight;
    CGFloat weekdayViewHeight;
    CGRect shrinkFrame;
    NSMutableArray *weekdayArray;
    CGRect dateGroupFrame;
    UIView *borderView ;
    CGRect borderFrame;
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
    _dateGroupView.backgroundColor = [UIColor whiteColor];
    
    dateGroupFrame = _dateGroupView.frame;
    borderView = [[UIView alloc]initWithFrame:CGRectMake(10, weekdayViewHeight+dateGroupFrame.size.height, 300, 1)];
    borderView.backgroundColor = [UIColor colorWithWhite:0.667 alpha:0.500];
    borderFrame = borderView.frame;

    
    _dateGroupView.layer.borderColor = [[UIColor greenColor]CGColor];
    _dateGroupView.layer.borderWidth = 2.0f;
    
    self.layer.borderColor = [[UIColor yellowColor]CGColor];
    self.layer.borderWidth = 2.0f;
    [self addSubview:_dateGroupView];
    
    NSArray *weekDay = @[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"];
    weekdayArray = [[NSMutableArray alloc]init];
    
    // Set weekdays
    for (int i=1;i<8;i++) {
        WeekdayView *dateView = [[WeekdayView alloc]initWithFrame:CGRectMake(xOffSet,yOffSet,dateViewWidth,weekdayViewHeight)];
        [dateView.dateLabel setText:weekDay[i-1]];
        dateView.dateLabel.frame = CGRectMake(0,0, dateViewWidth, weekdayViewHeight);
        [self addSubview:dateView];
        xOffSet += dateViewWidth;
        dateView.row = -1;
        [weekdayArray addObject:dateView];
    }
    monthViewFrame = self.frame;
    [self addSubview:borderView];

    shrinkFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, weekdayViewHeight + dateViewHeight);
    // Init date labels

    [self setupCalendar:_monthModel];
}

- (void)setupCalendar:(MonthModel *)monthModel
{
    [self removeCalendarView];
    _monthModel = monthModel;
    self.frame = monthViewFrame;
    _dateGroupView.frame = dateGroupFrame;
    borderView.frame = borderFrame;
    
    // Define x , y offset for date view
    CGFloat xOffSet = 0;
//    CGFloat yOffSet = weekdayViewHeight;
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
        dateView.row = dateModel.row;
        dateView.tag = i; // Index to link view and date model
        dateView.date = dateModel.date;
        [dateView.dateLabel setText:[NSString stringWithFormat:@"%ld",(long)dateComp.day]];
        
        // Configure color for dates not in current month
        if (dateModel.isCurrentMonth)
            dateView.dateLabel.textColor = [UIColor blackColor];
        else
            dateView.dateLabel.textColor = [UIColor colorWithWhite:0.500 alpha:0.500];
        
        // Configure color for today
        if (dateModel.isToday) {
            dateView.isToday = YES;
            dateView.dateLabel.textColor = Rgb2UIColor(255, 0, 0);
        }
        
        if (_shrink && i%7==0) {
            dateView.dateLabel.backgroundColor = Rgb2UIColor(33, 138, 251);
        }
        
        // Add indicator if date has event
        if (dateModel.hasEvent)
            [dateView addHasEventView];
        
//        [self addSubview:dateView];
        xOffSet += dateViewWidth;

        // Switch dateview Y position for week change
        if (i%7 == 6) {
            yOffSet += dateViewHeight;
            xOffSet = 0;
        }
        dateView.column = i%7;
        [_dateGroupView addSubview:dateView];
    }
}

- (void)removeCalendarView
{
    for (DateView *subview in _dateGroupView.subviews) {
//        if (subview.row > -1)
            [subview removeFromSuperview];
    }
}

- (void)shrinkCalendarWithRow:(int)row
{
    if (!self.shrink) {
        __block CGFloat shiftOffset = row * dateViewHeight;
        NSMutableArray *removedView = [[NSMutableArray alloc]init];
        
        [UIView animateWithDuration:1.0f animations:^{
            
            _dateGroupView.frame = CGRectOffset(_dateGroupView.frame, 0, -shiftOffset);
            borderView.frame = CGRectOffset(borderView.frame, 0, -shiftOffset);
            
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5f animations:^{
                
                _dateGroupView.frame = CGRectMake(dateGroupFrame.origin.x,
                                                  _dateGroupView.frame.origin.y,
                                                  dateGroupFrame.size.width,
                                                  dateGroupFrame.size.height - dateViewHeight);
                
                
                // Expand the calendar based on select row
                for (DateView *view in _dateGroupView.subviews) {
                    
                    
                    if (view.row != row && view.row > -1) {
                        [removedView addObject:view];
                        view.alpha = 0;
                    }
                    else if (view.row >-1) {
                        //view.frame = CGRectOffset(view.frame, 0, -shiftOffset);
                    }
                }
                
                
                
                borderView.frame =CGRectMake(10 ,
                                             dateGroupFrame.origin.y+dateViewHeight,
                                             300,
                                             1);
                
                
                
            } completion:^(BOOL finished) {
                for (DateView *v in removedView) {
                    [v removeFromSuperview];
                }
                self.frame = shrinkFrame;
            }];
        }];
    }
}

- (void)setAppearanceOnSelectDate:(NSDate *)date
{
    DateView *view =[self viewFromDate:date];
    WeekdayView *weekdayView = weekdayArray[view.column];
    weekdayView.selectedLabel.hidden = NO;

    CATransition *animation = [CATransition animation];
    animation.duration = 0.5f;
    animation.type = kCATransitionFade;
    animation.subtype = kCATransitionFromBottom;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    [view.dateLabel.layer addAnimation:animation forKey:nil];
    [weekdayView.selectedLabel.layer addAnimation:animation forKey:nil];

    if (view.isToday) {
        view.dateLabel.backgroundColor = Rgb2UIColor(255, 0, 0);
        weekdayView.selectedLabel.backgroundColor = Rgb2UIColor(255, 0, 0);
    }
    else {
        view.dateLabel.backgroundColor = Rgb2UIColor(33, 138, 251);
        weekdayView.selectedLabel.backgroundColor = Rgb2UIColor(33, 138, 251);
    }
    
    view.dateLabel.textColor = [UIColor whiteColor];
    view.isSelected = YES;
}

- (void)setAppearanceOnDeselectDate:(NSDate *)date dateNotInCurrentMonth:(BOOL)inMonth
{
    DateView *view =[self viewFromDate:date];
    WeekdayView *weekdayView = weekdayArray[view.column];
    weekdayView.selectedLabel.hidden = YES;

    CATransition *animation = [CATransition animation];
    animation.duration = 0.5f;
    animation.type = kCATransitionFade;
    animation.subtype = kCATransitionFromTop;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [view.dateLabel.layer addAnimation:animation forKey:nil];
    [weekdayView.selectedLabel.layer addAnimation:animation forKey:nil];

    if (!inMonth)
        view.dateLabel.textColor = [UIColor colorWithWhite:0.500 alpha:0.500];
    else
        view.dateLabel.textColor = [UIColor blackColor];

    view.dateLabel.backgroundColor =[UIColor clearColor];
    view.isSelected = NO;
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
