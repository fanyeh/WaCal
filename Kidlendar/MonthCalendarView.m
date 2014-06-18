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
#import <QuartzCore/QuartzCore.h>
#import "NSString+Localization.h"

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
    NSArray *solarTermFirst;
    NSArray *solarTermLast;
    NSString *weekStart;
    NSArray *weekDay;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _shrink =NO;
        solarTermFirst = @[@"小寒", // 1
                                    @"立春", // 2
                                    @"驚蟄", // 3
                                    @"清明", // 4
                                    @"立夏", // 5
                                    @"芒種", // 6
                                    @"小暑", // 7
                                    @"立秋", // 8
                                    @"白露", // 9
                                    @"寒露", // 10
                                    @"立冬", // 11
                                    @"大雪"]; // 12
        
        
        solarTermLast = @[@"大寒", // 1
                                   @"雨水", // 2
                                   @"春分", // 3
                                   @"穀雨", // 4
                                   @"小滿", // 5
                                   @"夏至", // 6
                                   @"大暑", // 7
                                   @"處暑", // 8
                                   @"秋分", // 9
                                   @"霜降", // 10
                                   @"小雪", // 11
                                   @"冬至"]; //12

        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        _shrink =NO;
        solarTermFirst = @[@"小寒", // 1
                           @"立春", // 2
                           @"驚蟄", // 3
                           @"清明", // 4
                           @"立夏", // 5
                           @"芒種", // 6
                           @"小暑", // 7
                           @"立秋", // 8
                           @"白露", // 9
                           @"寒露", // 10
                           @"立冬", // 11
                           @"大雪"]; // 12
        
        
        solarTermLast = @[@"大寒", // 1
                          @"雨水", // 2
                          @"春分", // 3
                          @"穀雨", // 4
                          @"小滿", // 5
                          @"夏至", // 6
                          @"大暑", // 7
                          @"處暑", // 8
                          @"秋分", // 9
                          @"霜降", // 10
                          @"小雪", // 11
                          @"冬至"]; //12
        
        
    }
    return self;
}

- (void)initCalendar:(MonthModel *)monthModel
{
    // Initialization code
    _monthModel = monthModel;
    CGFloat xOffSet = 0.0f;
    CGFloat yOffSet = 0.0f;
    weekdayViewHeight = 30;
    calendarWidth = self.frame.size.width;
    calendarHeight = self.frame.size.height - weekdayViewHeight;
    dateViewWidth = calendarWidth/7;
    dateViewHeight = calendarHeight/6;
    
    _dateGroupView = [[UIView alloc]initWithFrame:CGRectMake(0, weekdayViewHeight, calendarWidth,calendarHeight)];
    _dateGroupView.backgroundColor = [UIColor clearColor];
    
    dateGroupFrame = _dateGroupView.frame;

    [self addSubview:_dateGroupView];
    
    weekStart = [[NSUserDefaults standardUserDefaults]stringForKey:@"WeekStart"];

    if ([weekStart isEqualToString:@"Monday"] || weekStart == nil) {
        weekDay = @[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"];
    } else if ([weekStart isEqualToString:@"Sunday"]) {
        weekDay = @[@"Sun",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat"];
    }

    weekdayArray = [[NSMutableArray alloc]init];
    
    // Set weekdays
    for (int i=1;i<8;i++) {
        WeekdayView *dateView = [[WeekdayView alloc]initWithFrame:CGRectMake(xOffSet,yOffSet,dateViewWidth,weekdayViewHeight)];
        [dateView.dateLabel setText:NSLocalizedString(weekDay[i-1], nil)];
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

- (void)refreshWeekday
{
   weekStart = [[NSUserDefaults standardUserDefaults]stringForKey:@"WeekStart"];

    if ([weekStart isEqualToString:@"Monday"]|| weekStart == nil) {
        weekDay = @[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"];
    } else if ([weekStart isEqualToString:@"Sunday"]) {
        weekDay = @[@"Sun",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat"];
    }

    for (int i = 0; i < [weekdayArray count] ; i ++) {
        
        WeekdayView *dateView = [weekdayArray objectAtIndex:i];
        [dateView.dateLabel setText:NSLocalizedString(weekDay[i], nil)];
        
    }
    
}


- (void)setupCalendar:(MonthModel *)monthModel
{
    self.frame = monthViewFrame;
    _dateGroupView.frame = dateGroupFrame;
    
    BOOL showLunarCal;
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([language isEqualToString:@"zh-Hans"] || [language isEqualToString:@"zh-Hant"])
        showLunarCal = [[NSUserDefaults standardUserDefaults]boolForKey:@"LunarCalendar"];
    else
        showLunarCal = NO;

    
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

        
        // 計算24節氣 & 農曆日期
        if (showLunarCal && dateComp.year < 2021 && dateComp.year > 1920) {
            if (dateComp.day == [self solarTermA:dateComp.year andMonth:dateComp.month])
            {
                dateView.lunarDateLabel.text = NSLocalizedString((NSString *)[solarTermFirst objectAtIndex:dateComp.month-1], nil);
            }
            else if (dateComp.day == [self solarTermB:dateComp.year andMonth:dateComp.month])
            {
                dateView.lunarDateLabel.text = NSLocalizedString((NSString *)[solarTermLast objectAtIndex:dateComp.month-1], nil);
            }
            else {
                dateView.lunarDateLabel.text = [self LunarForSolar:dateModel.date];
            }
        } else {
            dateView.lunarDateLabel.text = nil;
        }
        
        // Configure color for dates not in current month
        if (dateModel.isCurrentMonth)
            dateView.dateLabel.textColor = [UIColor colorWithWhite:0.502 alpha:1.000];
        else
            dateView.dateLabel.textColor = [UIColor colorWithWhite:0.824 alpha:1.000];
        
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
    view.dateLabel.layer.masksToBounds = YES;
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
    if (!fadeDateView.isToday)
        fadeDateView.dateLabel.layer.cornerRadius = 0.0f;
    fadeDateView.dateLabel.layer.masksToBounds = NO;
}

- (DateView *)viewFromDate:(NSDate *)date
{
    for (DateView *d in _dateGroupView.subviews) {
        if (d.date==date)
            return d;
    }
    return nil;
}

// Lunar conversion function
- (NSString *) LunarForSolar: (NSDate *) solarDate {
    
    // base data about chinese year informace
    // 保存公历农历之间的转换信息:以任意一年作为起点，
    // 把从这一年起若干年(依需要而定)的农历信息保存起来。 要保存一年的信息，只要两个信息就够了: 1)农历每个月的大小;2)今年是否有闰月，闰几月以及闰月的大小。 用一个整数来保存这些信息就足够了。 具体的方法是:用一位来表示一个月的大小，大月记为1，小月记为0，
    // 这样就用掉12位(无闰月)或13位(有闰月)，再用高四位来表示闰月的月份，没有闰月记为0。 ※-----例----: 2000年的信息数据是0xc96，化成二进制就是110010010110B，
    // 表示的含义是:1、2、5、8、10、11月大，其余月份小。 2001年的农历信息数据是0x1a95(因为闰月，所以有13位)，
    // 具体的就是1、2、4、5、8、10、12月大， 其余月份小(0x1a95=1101010010101B)，
    // 4月的后面那一个0表示的是闰4月小，接着的那个1表示5月大。 这样就可以用一个数组来保存这些信息。在这里用数组lunarInfo[]来保存这些信息
    
//    lunarInfo=@[
//                @0x04bd8,@0x04ae0,@0x0a570,@0x054d5,@0x0d260, 1900 - 1904
//                @0x0d950,@0x16554,@0x056a0,@0x09ad0,@0x055d2, 1905
//                @0x04ae0,@0x0a5b6,@0x0a4d0,@0x0d250,@0x1d255, 1910
//                @0x0b540,@0x0d6a0,@0x0ada2,@0x095b0,@0x14977, 1915
//                @0x04970,@0x0a4b0,@0x0b4b5,@0x06a50,@0x06d40, 1920
//                @0x1ab54,@0x02b60,@0x09570,@0x052f2,@0x04970, 1925
//                @0x06566,@0x0d4a0,@0x0ea50,@0x06e95,@0x05ad0, 1930
//                @0x02b60,@0x186e3,@0x092e0,@0x1c8d7,@0x0c950, 1935
//                @0x0d4a0,@0x1d8a6,@0x0b550,@0x056a0,@0x1a5b4, 1940
//                @0x025d0,@0x092d0,@0x0d2b2,@0x0a950,@0x0b557, 1945
//                @0x06ca0,@0x0b550,@0x15355,@0x04da0,@0x0a5d0, 1950
//                @0x14573,@0x052d0,@0x0a9a8,@0x0e950,@0x06aa0, 1955
//                @0x0aea6,@0x0ab50,@0x04b60,@0x0aae4,@0x0a570, 1960
//                @0x05260,@0x0f263,@0x0d950,@0x05b57,@0x056a0, 1965
//                @0x096d0,@0x04dd5,@0x04ad0,@0x0a4d0,@0x0d4d4, 1970
//                @0x0d250,@0x0d558,@0x0b540,@0x0b5a0,@0x195a6, 1975
//                @0x095b0,@0x049b0,@0x0a974,@0x0a4b0,@0x0b27a, 1980
//                @0x06a50,@0x06d40,@0x0af46,@0x0ab60,@0x09570, 1985
//                @0x04af5,@0x04970,@0x064b0,@0x074a3,@0x0ea50, 1990
//                @0x06b58,@0x055c0,@0x0ab60,@0x096d5,@0x092e0, 1995
//                @0x0c960,@0x0d954,@0x0d4a0,@0x0da50,@0x07552, 2000
//                @0x056a0,@0x0abb7,@0x025d0,@0x092d0,@0x0cab5, 2005
//                @0x0a950,@0x0b4a0,@0x0baa4,@0x0ad50,@0x055d9, 2010
//                @0x04ba0,@0x0a5b0,@0x15176,@0x052b0,@0x0a930, 2015
//                @0x07954,@0x06aa0,@0x0ad50,@0x05b52,@0x04b60, 2020
//                @0x0a6e6,@0x0a4e0,@0x0d260,@0x0ea65,@0x0d530, 2025
//                @0x05aa0,@0x076a3,@0x096d0,@0x04bd7,@0x04ad0, 2030
//                @0x0a4d0,@0x1d0b6,@0x0d250,@0x0d520,@0x0dd45, 2035
//                @0x0b5a0,@0x056d0,@0x055b2,@0x049b0,@0x0a577, 2040
//                @0x0a4b0,@0x0aa50,@0x1b255,@0x06d20,@0x0ada0]; 2045
    

    
    // Heavenly Name 甲、乙、丙、丁、戊、己、庚、辛、壬、癸
    NSArray * cTianGan = @[@"甲",@"乙",@"丙 ",@"丁",@"戊",@"己",@"庚",@"辛",@"壬",@"癸"];
    
    // Earthly name 子、丑、寅、卯、辰、巳、午、未、申、酉、戍、亥
    NSArray * cDiZhi = @[@"子",@"丑",@"寅",@"卯",@"辰",@"巳",@"午",@"未",@"申",@"酉",@"戍",@"亥"];
    
    // Zodiac Name 鼠　牛　虎　兔　龍　蛇　馬　羊　猴　雞　狗　豬
    NSArray * cShuXiang = @[@"鼠",@"牛",@"虎",@"兔",@"龍",@"蛇",@"馬",@"羊",@"猴",@"雞",@"狗",@"豬"];
    
    // Lunar name
    NSArray * cDayName = @[@"初一",@"初二",@"初三",@"初四",@"初五",@"初六",@"初七",@"初八",@"初九",@"初十",
                           @"十一",@"十二",@"十三",@"十四",@"十五",@"十六",@"十七",@"十八",@"十九",@"二十",
                           @"廿一",@"廿二",@"廿三",@"廿四",@"廿五",@"廿六",@"廿七",@"廿八",@"廿九",@"三十",];
    
    // Lunar month name
    NSArray * cMonName = @[@"正月",@"二月",@"三月",@"四月",@"五月",@"六月",@"七月",@"八月",@"九月",@"十月",@"十一月",@"腊月"];
    
    
    // The front of the calendar each month days
    const int wMonthAdd [12] = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};
    
    // Lunar data
    const int wNongliData [100] = {
        
        2635, 333387, 1701, 1748, 267701, // 1921
        694, 2391, 133423, 1175, 396438,  // 1926
        3402, 3749, 331177, 1453, 694,    // 1931
        201326, 2350, 465197, 3221, 3402, // 1936
        400202, 2901, 1386, 267611, 605,  // 1941
        2349, 137515, 2709, 464533, 1738, // 1946
        2901, 330421, 1242, 2651, 199255, // 1951
        1323, 529706, 3733, 1706, 398762, // 1956
        2741, 1206, 267438, 2647, 1318,   // 1961
        204070, 3477, 461653, 1386, 2413, // 1966
        330077, 1197, 2637, 268877, 3365, // 1971
        531109, 2900, 2922, 398042, 2395, // 1976
        1179, 267415, 2635, 661067, 1701, // 1981
        1748, 398772, 2742, 2391, 330031, // 1986
        1175, 1611, 200010, 3749, 527717, // 1991
        1452, 2742, 332397, 2350, 3222,   // 1996
        268949, 3402, 3493, 133973, 1386, // 2001
        464219, 605, 2349, 334123, 2709,  // 2006
        2890, 267946, 2773, 592565, 1210, // 2011
        2651, 395863, 1323, 2707, 265877}; // 2016
    
    static NSInteger wCurYear, wCurMonth, wCurDay;
    static int nTheDate, nIsEnd, m, k, n, i, nBit;
    // Get the current calendar year, month, day
    NSDateComponents * components = [[NSCalendar currentCalendar] components: NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate: solarDate];
    wCurYear = [components year];
    wCurMonth = [components month];
    wCurDay = [components day];

    // February 8, 1921 the number of days of the initial time: 1921-2-8 (first day)
    nTheDate = (wCurYear - 1921) * 365 + (wCurYear - 1921) / 4 + wCurDay + wMonthAdd [wCurMonth - 1] - 38;
    
    if ((! (wCurYear% 4)) && (wCurMonth> 2))
        nTheDate = nTheDate + 1;
    
    // Calculate the Lunar Heavenly Stems and Earthly Branches, month, day
    nIsEnd = 0;
    m = 0;
    
    while (nIsEnd != 1)
    {
        if (wNongliData[m] < 4095)
            k = 11;
        else
            k = 12;
        
        n = k;
        
        while (n >= 0)
        {
            // Get of wNongliData (m) of the first n-bit binary value
            nBit = wNongliData[m];
            
            for (i = 1; i < n + 1; i ++) {
                nBit = nBit / 2;
            }
            
            nBit = nBit % 2;
            
            if (nTheDate <= (29 + nBit))
            {
                nIsEnd = 1;
                break;
            }
            
            nTheDate = nTheDate - 29 - nBit;
            
            n = n - 1;
        }
        if (nIsEnd)
            break;
        
        m = m + 1;
    }
    
    wCurYear = 1921 + m;
    wCurMonth = k - n + 1;
    wCurDay = nTheDate;
    
    if (k == 12)
    {
        if (wCurMonth == wNongliData[m] / 65536 + 1)
            wCurMonth = 1 - wCurMonth;
        else if (wCurMonth> wNongliData[m] / 65536 + 1)
            wCurMonth = wCurMonth - 1;
    }
    
    // Generate Lunar Heavenly Stems and Earthly Branches, sign of the Zodiac
    NSString * szShuXiang = (NSString *) [cShuXiang objectAtIndex: ((wCurYear - 4)% 60)% 12];
    NSString * szNongli = [NSString stringWithFormat: @"%@ (%@%@) years",
                           
                           szShuXiang,
                           (NSString *)[cTianGan objectAtIndex: ((wCurYear - 4)% 60)% 10],
                           (NSString *)[cDiZhi objectAtIndex: ((wCurYear - 4)% 60)% 12]];
    
    
    // Generate the Lunar month, day
    NSString * szNongliDay;
    
    if (wCurMonth <1) {
        
        szNongliDay = [NSString stringWithFormat: @"leap%@",(NSString *) [cMonName objectAtIndex: - 1 * wCurMonth]];
        
    } else {
        
        szNongliDay = (NSString *) [cMonName objectAtIndex: wCurMonth-1];
        
    }

    //NSString * lunarDate = [NSString stringWithFormat:@"%@ %@ month %@ ", szNongli , szNongliDay, (NSString *)[cDayName objectAtIndex: wCurDay-1]];
    
    
    return [cDayName objectAtIndex: wCurDay-1];
    
    
    //[self Lunar:solarDate];
}

- (int)solarTermA:(NSInteger)year andMonth:(NSInteger)month
{
    
    //    小寒
    //    　　21世纪C=5.4055，20世纪=6.11。
    //    　　例外：1982年计算结果加1日，2019年减1日。
    //    立春
    //       21世纪C值=3.87，22世纪C值=4.15。
    //    惊蛰
    //    　 21世纪惊蛰的C值=5.63。
    //    清明
    //    　　21世纪C=4.81，20世纪=5.59。
    //    立夏
    //    　　21世纪C=5.52，20世纪=6.318。
    //    　　例外：1911年的计算结果加1日。
    //    芒种
    //    　　21世纪C=5.678，20世纪=6.5。
    //    　　例外：1902年的计算结果加1日。
    //    小暑
    //    　　21世纪C=7.108，20世纪=7.928。
    //    　　例外：1925年和2016年的计算结果加1日。
    //    立秋
    //    　　21世纪C=7.5，20世纪=8.35。
    //    　　例外：2002年的计算结果加1日。
    //    白露
    //    　　21世纪C=7.646，20世纪=8.44。
    //    　　例外：1927年的计算结果加1日。
    //    寒露
    //    　　21世纪C=8.318，20世纪=9.098。
    //    立冬
    //    　　21世纪C=7.438，20世纪=8.218。
    //    　　例外：2089年的计算结果加1日。
    //    大雪
    //    　　21世纪C=7.18，20世纪=7.9。
    //    　　例外：1954年的计算结果加1日。
    
    static float solarTermFirstConstant[12] =
    {
        5.4055,
        3.87,
        5.63,
        4.81,
        5.52,
        5.678,
        7.108,
        7.5,
        7.646,
        8.318,
        7.438,
        7.18
    };
    
    // 24節氣計算公式 : [Y×D+C]-L
    // Y=年代数、D=0.2422、L=闰年数、C取决于节气和年份。
    // 本世纪立春的C值=4.475，求2017年的立春日期如下：
    // [2017×0.2422+4.475]-[2017/4-15]=492-489=3
    // 所以2017年的立春日期是2月3日。
    NSInteger y;
    if (year > 1999) {
        y = year - 2000;
        
    } else {
        y = year - 1900;
    }
    float D = 0.2422;
    float C = (float)solarTermFirstConstant[month-1];
    int day = floor((y * D + C)) - floor((y/4));
//    NSLog(@"Year %ld  month %ld Day %d",year,month,day);

    return day;
}

- (int)solarTermB:(NSInteger)year andMonth:(NSInteger)month
{
    
    //    大寒
    //    　　21世纪C=20.12，20世纪C=20.84。
    //    　　例外：2082年的计算结果加1日，20世纪无
    //    雨水
    //      21世纪雨水的C值18.73。
    //      例外：2026年计算得出的雨水日期应调减一天为18日。
    //    春分
    //      21世纪春分的C值=20.646。
    //      例外：2084年的计算结果加1日。
    //    谷雨
    //    　　21世纪C=20.1，20世纪=20.888。
    //    小满
    //    　　21世纪C=21.04，20世纪=21.86。
    //    　　例外：2008年的计算结果加1日。
    //    夏至
    //    　　21世纪C=21.37，20世纪=22.20。
    //    　　例外：1928年的计算结果加1日。
    //    大暑
    //    　　21世纪C=22.83，20世纪=23.65。
    //    　　例外：1922年的计算结果加1日。
    //    处暑
    //    　　21世纪C=23.13，20世纪=23.95。
    //    　　例外：无。
    //    秋分
    //    　　21世纪C=23.042，20世纪=23.822。
    //    　　例外：1942年的计算结果加1日。
    //    霜降
    //    　　21世纪C=23.438，20世纪=24.218。
    //    　　例外：2089年的计算结果加1日。
    //    小雪
    //    　　21世纪C=22.36，20世纪=23.08。
    //    　　例外：1978年的计算结果加1日。
    //    冬至
    //    　　21世纪C=21.94，20世纪=22.60。
    //    　　例外：1918年和2021年的计算结果减1日。
    
    static float solarTermLastConstant[12] =
    {
        20.12,
        18.73,
        20.646,
        20.1,
        21.04,
        21.37,
        22.83,
        23.13,
        23.042,
        23.438,
        22.36,
        21.94
    };
    
    // 24節氣計算公式 : [Y×D+C]-L
    // Y=年代数、D=0.2422、L=闰年数、C取决于节气和年份。
    // 本世纪立春的C值=4.475，求2017年的立春日期如下：
    // [2017×0.2422+4.475]-[2017/4-15]=492-489=3
    // 所以2017年的立春日期是2月3日。
    NSInteger y;
    if (year > 1999) {
        y = year - 2000;
        
    } else {
        y = year - 1900;
    }
    
    float D = 0.2422;
    float C = (float)solarTermLastConstant[month-1];
    int day = floor((y * D + C)) - floor((y/4));
//    NSLog(@"Year %ld  month %ld Day %d",year,month,day);

    return day;
}


@end
