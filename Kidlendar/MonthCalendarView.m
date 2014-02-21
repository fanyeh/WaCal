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

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@implementation MonthCalendarView
CGFloat dateViewWidth;
CGFloat dateViewHeight;
CGFloat weekdayComponentHeight;
CGRect monthViewFrame;
CGFloat calendarWidth;
CGFloat calendarHeight;
CGFloat weekdayViewHeight;


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
    calendarWidth = 320;
    calendarHeight = 250;
    
    dateViewWidth = calendarWidth/7;
    dateViewHeight = calendarHeight/6;
    weekdayViewHeight = 20;
    NSArray *weekDay = @[@"M",@"T",@"W",@"T",@"F",@"S",@"S"];
    
    // Set weekdays
    for (int i=1;i<8;i++) {
        DateView *dateView = [[DateView alloc]initWithFrame:CGRectMake(xOffSet,yOffSet,dateViewWidth,weekdayViewHeight)];
        [dateView.dateLabel setText:weekDay[i-1]];
        dateView.dateLabel.frame = CGRectMake(0,0, dateViewWidth, weekdayViewHeight);
        dateView.dateLabel.textColor =  [UIColor colorWithWhite:0.702 alpha:1.000];
        dateView.dateLabel.font = [UIFont fontWithName:@"Avenir-Light" size:15];
        [self addSubview:dateView];
        xOffSet += dateViewWidth;
        dateView.row = -1;
    }
    monthViewFrame = self.frame;
    
    // Init date labels
    [self setupCalendar:_monthModel];
}

- (void)setupCalendar:(MonthModel *)monthModel
{
    [self removeCalendarView];
    _monthModel = monthModel;
    // Define x , y offset for date view
    CGFloat xOffSet = 0;
    CGFloat yOffSet = weekdayViewHeight;
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
//            dateView.dateLabel.layer.cornerRadius = dateView.dateLabel.frame.size.width/2;
            dateView.dateLabel.backgroundColor = Rgb2UIColor(33, 138, 251);
        }
        
        // Add indicator if date has event
        if (dateModel.hasEvent)
            [dateView addHasEventView];
        
        [self addSubview:dateView];
        xOffSet += dateViewWidth;

        // Switch dateview Y position for week change
        if (i%7 == 6) {
            yOffSet += dateViewHeight;
            xOffSet = 0;
        }
    }
}

- (void)removeCalendarView
{
    for (DateView *subview in [self subviews]) {
        if (subview.row > -1)
            [subview removeFromSuperview];
    }
}

- (CGRect)shrinkCalendarWithRow:(int)row
{
    // Expand the calendar based on select row
    CGFloat viewHeight = self.frame.size.height - dateViewHeight*2+5;
    for (DateView *view in self.subviews) {
        if (view.row != row && view.row > -1) {
            [view removeFromSuperview];
        }
        else if (view.row >-1) {
            CGRect defaultPosition = view.frame;
            CGRect expandPosition = CGRectMake(defaultPosition.origin.x,weekdayViewHeight, defaultPosition.size.width, defaultPosition.size.height);
            view.frame = expandPosition;
        }
    }
    CGRect detailViewFrame = CGRectMake(0, dateViewHeight*2+5, calendarWidth, viewHeight);
    return detailViewFrame;
}

- (void)setAppearanceOnSelectDate:(NSDate *)date
{
    DateView *view =[self viewFromDate:date];
//    view.dateLabel.layer.cornerRadius = view.dateLabel.frame.size.width/2;

    if (view.isToday) {
        view.dateLabel.backgroundColor = Rgb2UIColor(255, 0, 0);

//        view.dateLabel.layer.borderColor = [[UIColor grayColor]CGColor];
//        view.dateLabel.layer.borderWidth = 2.0f;
    }
    else
        view.dateLabel.backgroundColor = Rgb2UIColor(33, 138, 251);
    
    view.dateLabel.textColor = [UIColor whiteColor];
    view.isSelected = YES;
}

- (void)setAppearanceOnDeselectDate:(NSDate *)date dateNotInCurrentMonth:(BOOL)inMonth
{
    DateView *view =[self viewFromDate:date];
    if (!inMonth)
        view.dateLabel.textColor = [UIColor colorWithWhite:0.500 alpha:0.500];
    else
        view.dateLabel.textColor = [UIColor blackColor];
    
    if (!view.isToday)
        view.dateLabel.layer.cornerRadius = 0;
    view.dateLabel.backgroundColor =[UIColor clearColor];
    view.isSelected = NO;
}

- (DateView *)viewFromDate:(NSDate *)date
{
    for (DateView *d in self.subviews) {
        if (d.date==date)
            return d;
    }
    return nil;
}

@end
