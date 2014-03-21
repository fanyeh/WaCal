//
//  MonthViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "MonthViewController.h"
#import "DateView.h"
#import "EventCreateController.h"
#import <EventKit/EventKit.h>
#import "DiaryCreateViewController.h"
#import "DiaryDataStore.h"
#import "DiaryData.h"
#import "MonthModel.h"
#import "DateModel.h"
#import <AddressBook/AddressBook.h>
#import "UIImage+Resize.h"
#import "EventReviewController.h"
#import "DiaryCell.h"
#import "LocationData.h"
#import "LocationDataStore.h"
#import "EventTableCell.h"
#import "DiaryPageViewController.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@interface MonthViewController ()
{
    CGFloat detailViewHeight;
    UITableView *eventTableView;
    DateView *previousDateView;
    DateModel *previousDateModel;
    MonthModel *monthModel;
    EKEvent *_comingUpEvent;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    NSMutableArray *diaryArrayPhotos;
    UILabel *monthLabel;
    UILabel *yearLabel;
    NSDateFormatter *eventTimeFormatter;
    NSInteger selectedMonth;
    DiaryData *showDiaryData;
    
}

@property (weak, nonatomic) IBOutlet UIView *diaryView;
@property (weak, nonatomic) IBOutlet UILabel *comingEventTime;
@property (weak, nonatomic) IBOutlet UILabel *comingEventTimeEnd;
@property (weak, nonatomic) IBOutlet UILabel *comingEventTitle;
@property (weak, nonatomic) IBOutlet UIView *comingEventView;
@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (weak, nonatomic) IBOutlet UIImageView *diaryImageView;
@property (weak, nonatomic) IBOutlet UIView *dotViewGray;
@property (weak, nonatomic) IBOutlet UILabel *diaryTitle;
@property (weak, nonatomic) IBOutlet UILabel *diaryDate;
@property (weak, nonatomic) IBOutlet UILabel *diaryLocation;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetail;
@property (weak, nonatomic) IBOutlet UILabel *allDayLabel;
@property (weak, nonatomic) IBOutlet UIView *emptyDiaryView;
@property (weak, nonatomic) IBOutlet UIView *emptyEventView;
@property (weak, nonatomic) IBOutlet UIView *videoPlayView;
@property (weak, nonatomic) IBOutlet UIImageView *locationTag;
@property (weak, nonatomic) IBOutlet UILabel *endEventLabel;


@end

@implementation MonthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _gregorian = [NSCalendar currentCalendar];
        [_gregorian setTimeZone:[NSTimeZone systemTimeZone]];
        monthModel = [[MonthModel alloc]initMonthCalendarWithDate:[NSDate date] andCalendar:_gregorian];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    self.view.layer.borderColor = [Rgb2UIColor(33, 138, 251) CGColor];
//    self.view.layer.borderWidth = 5.0f;

    UITapGestureRecognizer *emptyEventTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addEvent)];
    UITapGestureRecognizer *emptyDiaryTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addDiary)];

    [_emptyDiaryView addGestureRecognizer:emptyDiaryTap];
    [_emptyEventView addGestureRecognizer:emptyEventTap];

    _videoPlayView.layer.cornerRadius = _videoPlayView.frame.size.width/2;
    _videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
    _videoPlayView.layer.borderWidth = 3.0f;
    
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    eventTimeFormatter = [[NSDateFormatter alloc]init];
    eventTimeFormatter.dateFormat = @"hh:mm aa";
    eventTimeFormatter.timeZone = [NSTimeZone systemTimeZone];
    

    UITapGestureRecognizer *eventTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showEventView)];
    [_comingEventView addGestureRecognizer:eventTap];
    _dotView.layer.cornerRadius = _dotView.frame.size.width/2;
    
    _dotViewGray.layer.cornerRadius = _dotView.frame.size.width/2;
    
    
    _selectedDate = [monthModel dateModelForDate:[NSDate date]].date;
    [_monthView initCalendar:monthModel];
    [self resetCalendarBySelectDate:NO];
    
    NSDateComponents *comp = [_gregorian components:NSMonthCalendarUnit
                                           fromDate:_selectedDate];
    
    selectedMonth = [comp month];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(forwardMonth:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                    action:@selector(rewindMonth:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                 action:@selector(shrinkMonthWithAnimation)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(expandMonthWithAnimation)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    
    [_monthView addGestureRecognizer:swipeLeft];
    [_monthView addGestureRecognizer:swipeRight];
    [_monthView addGestureRecognizer:swipeUp];
    [_monthView addGestureRecognizer:swipeDown];
    
    // Show diary gesture
    UITapGestureRecognizer *diaryTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(diaryTap)];
    [_diaryView addGestureRecognizer:diaryTap];

    // Set up table for events
    CGRect eventTableFrame = CGRectMake(0,
                                        _comingEventView.frame.origin.y,
                                        self.view.frame.size.width,
                                        _diaryView.frame.origin.y-(_monthView.shrinkFrame.origin.y+_monthView.shrinkFrame.size.height));
    eventTableView = [[UITableView alloc]initWithFrame:eventTableFrame style:UITableViewStyleGrouped];
    eventTableView.dataSource = self;
    eventTableView.backgroundColor = [UIColor clearColor];
    eventTableView.hidden = YES;
    eventTableView.delegate = self;
    eventTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [eventTableView registerNib:[UINib nibWithNibName:@"EventTableCell" bundle:nil] forCellReuseIdentifier:@"Cell"];

    [self.view addSubview:eventTableView];
    
    // Bar button for adding event
    UIBarButtonItem *addEventButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addEvent)];
//    UIBarButtonItem *addDiaryButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"newDiary22.png"] style:UIBarButtonItemStylePlain target:self action:@selector(addDiary)];
    
    
//    self.navigationItem.rightBarButtonItems = @[addEventButton,addDiaryButton];
    self.navigationItem.rightBarButtonItem = addEventButton;

    
    // Custom navgation left button view
    UIView *leftBarButtonView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150, 44)];
    monthLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 5, 150, 24)];
    monthLabel.textColor = [UIColor whiteColor];
    monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    [leftBarButtonView addSubview:monthLabel];
    yearLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 24, 100, 20)];
    yearLabel.textColor = [UIColor whiteColor];
    yearLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    [leftBarButtonView addSubview:yearLabel];
    UIBarButtonItem *monthButton = [[UIBarButtonItem alloc]initWithCustomView:leftBarButtonView];
    self.navigationItem.leftBarButtonItem = monthButton;
    [self setNavgationBarTitle];
    
    // Add observer to monitor event when new calendar event is created or removed
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshCalendarOnEventChange:)
                                                name:@"eventChange" object:nil];
    
    // Add observer to monitor event when new calendar event is created or removed
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshDiary:)
                                                name:@"diaryChange" object:nil];
    
    // Add observer to monitor event when switch EKCalendar
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(switchEKCalendar:)
                                                name:@"EKCalendarSwitch" object:nil];
    
    [self showDiary];
}

//- (void)viewWillDisappear:(BOOL)animated
//{
//    _monthView.hidden = YES;
//}
//
//-(void)viewWillAppear:(BOOL)animated
//{
//    _monthView.hidden  = NO;
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setNavgationBarTitle
{
    NSDateComponents *comp = [_gregorian components:(
                                                     NSYearCalendarUnit|
                                                     NSMonthCalendarUnit|
                                                     NSDayCalendarUnit|
                                                     NSHourCalendarUnit
                                                     )
                                           fromDate:_selectedDate];
    
    NSArray *monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];
    if (selectedMonth !=[comp month]) {
        NSString *month = monthArray[[comp month]-1];
        NSInteger currentMonth = [monthArray indexOfObject:monthLabel.text];
        NSInteger currentYear = [yearLabel.text integerValue];
        
        // Add transition (must be called after myLabel has been displayed)
        CATransition *animation = [CATransition animation];
        animation.duration = 1.0f;
        animation.type = kCATransitionReveal;
        
        // Forward or Rewind month
        if (currentMonth > ([comp month]-1))
            animation.subtype = kCATransitionFromLeft;
        else
            animation.subtype = kCATransitionFromRight;
        
        // Forward or Rewind year
        if (currentYear > [comp year])
            animation.subtype = kCATransitionFromLeft;
        else if (currentYear < [comp year])
            animation.subtype = kCATransitionFromRight;
        
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [monthLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
        monthLabel.text = month;
        yearLabel.text = [NSString stringWithFormat:@"%ld",(long)[comp year]];
        selectedMonth = [comp month];
    } else {
        monthLabel.text = monthArray[selectedMonth-1];
        yearLabel.text = [NSString stringWithFormat:@"%ld",(long)[comp year]];
    }
}

#pragma mark - UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EventTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    EKEvent *event = monthModel.eventsInDate[indexPath.row];
    cell.titleLabel.text = event.title;
    cell.dotView.layer.cornerRadius = cell.dotView.frame.size.width/2;
    
    if (!event.location) {
        cell.titleLabel.frame = CGRectOffset(cell.titleLabel.frame, 0, 12);
    }

    if ([event.startDate compare:[NSDate date]] == NSOrderedAscending)
        cell.eventEndLabel.hidden = NO;
    else
        cell.eventEndLabel.hidden = YES;
    
    if (event.allDay) {
        cell.alldayLabel.hidden = NO;
        cell.startDateLabel.hidden = YES;
        cell.endDateLabel.hidden = YES;
    } else {
        cell.alldayLabel.hidden = YES;
        cell.startDateLabel.text = [eventTimeFormatter stringFromDate: event.startDate];
        cell.endDateLabel.text = [eventTimeFormatter stringFromDate: event.endDate];
        cell.startDateLabel.hidden = NO;
        cell.endDateLabel.hidden = NO;
    }

    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [monthModel.eventsInDate count];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 59;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   _comingUpEvent = monthModel.eventsInDate[indexPath.row];
    [self showEventView];
}

#pragma mark - Notifications

-(void)refreshCalendarOnEventChange:(NSNotification *)notification
{
    NSLog(@"event change");
    NSDate *eventDate = [notification.userInfo objectForKey:@"startDate"];;
    _selectedDate = eventDate;
    [self resetCalendarBySelectDate:YES];
    if (_monthView.shrink)
        [self shrinkMonthWithOutAnimation];
}

-(void)refreshDiary:(NSNotification *)notification
{
    [self resetCalendarBySelectDate:NO];
//    [self showDiary];
}

- (void)switchEKCalendar:(NSNotification *)notification
{
    [self resetCalendarBySelectDate:NO];
    if (_monthView.shrink)
        [self shrinkMonthWithOutAnimation];
}

#pragma mark -UIGesture

-(void)diaryTap
{
    DiaryPageViewController *controller = [[DiaryPageViewController alloc]init];
    controller.diaryData = showDiaryData;
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)showEventView
{
    EventReviewController *evc = [[EventReviewController alloc]init];
    evc.event = _comingUpEvent;
    evc.selectedDate = _selectedDate;
    [self.navigationController pushViewController:evc animated:YES];
}

- (void)forwardMonth:(UITapGestureRecognizer *)sender
{
    if (_monthView.shrink)
        [self switchCalendarByWeek:kCalendarForward bySelectDate:NO];
    else
        [self switchCalendarByMonth:kCalendarForward bySelectDate:NO];
}

- (void)rewindMonth:(UITapGestureRecognizer *)sender
{
    if (_monthView.shrink)
        [self switchCalendarByWeek:kCalendarRewind bySelectDate:NO];
    else
        [self switchCalendarByMonth:kCalendarRewind bySelectDate:NO];
}

- (void)shrinkMonthWithOutAnimation
{
    _comingEventView.hidden = YES;
    [_monthView shrinkCalendarWithRow:[monthModel rowNumberForDate:_selectedDate]withAnimation:NO complete:^{
        [self showEventTable];
    }];
}

- (void)shrinkMonthWithAnimation
{
    _comingEventView.hidden = YES;
    [_monthView shrinkCalendarWithRow:[monthModel rowNumberForDate:_selectedDate]withAnimation:YES complete:^{
        [self showEventTable];
    }];
}

-(void)expandMonthWithOutAnimation
{
    if (_monthView.shrink) {
        eventTableView.hidden = YES;
        [_monthView expandCalendarWithRow:[monthModel rowNumberForDate:_selectedDate]withAnimation:NO complete:^{
            [self showComingEvent];
        }];
    }
}

-(void)expandMonthWithAnimation
{
    _dotView.hidden = NO;
    if (_monthView.shrink) {
        eventTableView.hidden = YES;
        [_monthView expandCalendarWithRow:[monthModel rowNumberForDate:_selectedDate]withAnimation:YES complete:^{
            [self showComingEvent];
        }];
    }
}

- (void)switchCalendarByMonth:(SwitchCalendar)forwardOrRewind bySelectDate:(BOOL)bySelect
{
    NSDateComponents *dateComponents = [_gregorian components:(
                                                               NSYearCalendarUnit |
                                                               NSMonthCalendarUnit|
                                                               NSDayCalendarUnit |
                                                               NSHourCalendarUnit |
                                                               NSMinuteCalendarUnit |
                                                               NSSecondCalendarUnit
                                                               )
                                                     fromDate:_selectedDate];

    // Add transition (must be called after myLabel has been displayed)
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = 0.3f;
    animation.type = kCATransitionPush;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    DateModel *selectedDateModel = [monthModel dateModelForDate:_selectedDate];
    if (forwardOrRewind==kCalendarRewind) {
        animation.subtype = kCATransitionFromLeft;
        if (selectedDateModel.isCurrentMonth)
            [dateComponents setMonth:([dateComponents month] - 1)];
    }
    else {
        animation.subtype = kCATransitionFromRight;
        if (selectedDateModel.isCurrentMonth)
            [dateComponents setMonth:([dateComponents month] + 1)];
    }
    
    if (!bySelect) {
        // Set _selected date to 1st date of previous/next month
        dateComponents.day = 1;
        _selectedDate = [_gregorian dateFromComponents:dateComponents];
    }
    [_monthView.dateGroupView.layer addAnimation:animation forKey:nil];
    [self resetCalendarBySelectDate:bySelect];
}

- (void)switchCalendarByWeek:(SwitchCalendar)forwardOrRewind bySelectDate:(BOOL)bySelect
{
    // Normalize selectedDate to dateModel's date
    NSDateComponents *dateComponents = [_gregorian components:(
                                                               NSYearCalendarUnit |
                                                               NSMonthCalendarUnit|
                                                               NSDayCalendarUnit  |
                                                               NSWeekdayCalendarUnit |
                                                               NSWeekOfMonthCalendarUnit
                                                               )
                                                     fromDate:_selectedDate];
    _selectedDate = [_gregorian dateFromComponents:dateComponents];
    long row = [monthModel rowNumberForDate:_selectedDate];

    // Add transition (must be called after myLabel has been displayed)
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3f;
    animation.type = kCATransitionPush;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    DateModel *selectedDateModel = [monthModel dateModelForDate:_selectedDate];

    // Rewind = 0 , Forward = 1
    if (forwardOrRewind==kCalendarRewind) {
        animation.subtype = kCATransitionFromLeft;
        row = row - 1;
        if (!bySelect) {
            if (row <0) {
                // Update month model to previous month
                if (selectedDateModel.isCurrentMonth) {
                    dateComponents.month -= 1;
                    dateComponents.day = 1; // Set to first date in case last date can be different for each month
                }
                _selectedDate = [_gregorian dateFromComponents:dateComponents];
            }
            else {
                DateModel *firstDateModelOfLastWeek = [[monthModel datesInMonth]objectAtIndex:row*7];
                _selectedDate = firstDateModelOfLastWeek.date;
            }
        }
    }
    else {
        animation.subtype = kCATransitionFromRight;
        row = row + 1;
        DateModel *d = [monthModel.datesInMonth lastObject];
        if (!bySelect) {
            if (row > d.row) {
                // Update month model to next month 1st monday
                if (selectedDateModel.isCurrentMonth) {
                    dateComponents.month += 1;
                    dateComponents.day = 1;  // Set to first date in case last date can be different for each month
                }
                _selectedDate = [_gregorian dateFromComponents:dateComponents];
            }
            else {
                DateModel *firstDateModelOfNextWeek = [[monthModel datesInMonth]objectAtIndex:row*7];
                _selectedDate = firstDateModelOfNextWeek.date;
            }
        }
    }
    [self resetCalendarBySelectDate:bySelect];
    [self shrinkMonthWithOutAnimation];
    
    if (!bySelect)
        [self.monthView.dateGroupView.layer addAnimation:animation forKey:nil];
}

- (void)dateLabelTap:(UITapGestureRecognizer *)sender
{
    DateView *dateView = (DateView*)sender.view;
    DateModel *dateModel = [[monthModel datesInMonth]objectAtIndex:dateView.tag];
    dateModel.isSelected = YES;

    if (![dateModel isEqual: previousDateView.date]) {
        [_monthView setAppearanceOnDeselectDate:previousDateModel.date dateNotInCurrentMonth:previousDateModel.isCurrentMonth];
        previousDateModel.isSelected = NO;
    }
    
    // Assign selectedDate based on tap
    _selectedDate = dateModel.date;
    
    // Change month title if selected date is in different month
    NSDateComponents *comp = [_gregorian components:NSMonthCalendarUnit
                                           fromDate:_selectedDate];
    
    // Switch month by selected date in different month
    if ([comp month] > selectedMonth) {
        if(_monthView.shrink)
           [self switchCalendarByWeek:kCalendarForward bySelectDate:YES];
        else
            [self switchCalendarByMonth:kCalendarForward bySelectDate:YES];
    } else if ([comp month] <  selectedMonth){
        if(_monthView.shrink)
            [self switchCalendarByWeek:kCalendarRewind bySelectDate:YES];
        else
            [self switchCalendarByMonth:kCalendarRewind bySelectDate:YES];
    }

    // Set up position of event & diary detail view
    [_monthView setAppearanceOnSelectDate:dateModel.date];
    
    if (_monthView.shrink) {
        [self showEventTable];
        // Change nav bar title if month is shrinked and selected is in different month
        if ([comp month] != selectedMonth)
            [self setNavgationBarTitle];
    }
    else
        [self showComingEvent];
    
    [self showDiary];
    
    previousDateModel = dateModel;
}

- (void)activateDateLabelGesture
{
    for (DateView *subview in [_monthView.dateGroupView subviews]) {
        if (subview.row > -1) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(dateLabelTap:)];
            [subview addGestureRecognizer:tapGesture];
        }
    }
}

- (void)showEventTable
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.8f;
    animation.type = kCATransitionPush;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    //            NSOrderedAscending //dateOne before dateTwo
    //            NSOrderedSame  //dateOne and dateTwo are the same
    //            NSOrderedDescending  //dateOne is after dateTwo
    
    if ([_selectedDate compare:[NSDate date]] == NSOrderedAscending)
        animation.subtype = kCATransitionFromLeft;
    else
        animation.subtype = kCATransitionFromRight;
    
    if ([monthModel checkEventForDate:_selectedDate]) {
        [eventTableView reloadData];
        _emptyEventView.hidden = YES;
        // Opens event and diary details on tap date
        [eventTableView.layer addAnimation:animation forKey:nil];
        eventTableView.hidden = NO;
        eventTableView.frame = CGRectMake(0,
                                          _monthView.shrinkFrame.origin.y+_monthView.shrinkFrame.size.height+11,
                                          self.view.frame.size.width,
                                          _diaryView.frame.origin.y-(_monthView.shrinkFrame.origin.y+_monthView.shrinkFrame.size.height));
    } else if (_emptyEventView.hidden){
        eventTableView.hidden = YES;
        [_emptyEventView.layer addAnimation:animation forKey:nil];
        _emptyEventView.hidden = NO;
    }
}

- (void)showComingEvent
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.8f;
    animation.type = kCATransitionPush;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    //            NSOrderedAscending //dateOne before dateTwo
    //            NSOrderedSame  //dateOne and dateTwo are the same
    //            NSOrderedDescending  //dateOne is after dateTwo
    
    if ([_selectedDate compare:previousDateModel.date] == NSOrderedAscending)
        animation.subtype = kCATransitionFromLeft;
    else
        animation.subtype = kCATransitionFromRight;
    
    if ([monthModel checkEventForDate:_selectedDate]) {
        if ([[[monthModel.eventsInDate lastObject]startDate] compare:[NSDate date]]== NSOrderedAscending) {
            _comingUpEvent = [monthModel.eventsInDate lastObject];
            [self updateComingEventViewEnds:YES];
            
        } else {
            for (EKEvent *comingUpEvent in monthModel.eventsInDate) {
                if([comingUpEvent.startDate compare:[NSDate date]] == NSOrderedDescending) {
                    // Assign to _comingUpEvent in case user tap event from _comingEventView
                    _comingUpEvent = comingUpEvent;
                    [self updateComingEventViewEnds:NO];
                    break;
                }
            }
        }
        _emptyEventView.hidden = YES;
        [_comingEventView.layer addAnimation:animation forKey:nil];
        _comingEventView.hidden = NO;
    }
   else if (_emptyEventView.hidden) {
       _comingEventView.hidden = YES;
       [_emptyEventView.layer addAnimation:animation forKey:nil];
       _emptyEventView.hidden = NO;
    }
}

-(void)updateComingEventViewEnds:(BOOL)ends
{
    if (ends)
        _endEventLabel.hidden = NO;
    else
        _endEventLabel.hidden = YES;
    
    if (_comingUpEvent.isAllDay) {
        _comingEventTime.hidden = YES;
        _comingEventTimeEnd.hidden = YES;
        _allDayLabel.hidden = NO;
        
    } else {
        _comingEventTime.hidden = NO;
        _comingEventTimeEnd.hidden = NO;
        _allDayLabel.hidden = YES;
        _comingEventTime.text  = [eventTimeFormatter stringFromDate:_comingUpEvent.startDate];
        _comingEventTimeEnd.text = [eventTimeFormatter stringFromDate:_comingUpEvent.endDate];
    }
    _comingEventTitle.text = _comingUpEvent.title;
}

-(void)showDiary
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.8f;
    animation.type = kCATransitionPush;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    //            NSOrderedAscending //dateOne before dateTwo
    //            NSOrderedSame  //dateOne and dateTwo are the same
    //            NSOrderedDescending  //dateOne is after dateTwo
    
    if ([_selectedDate compare:previousDateModel.date] == NSOrderedAscending)
        animation.subtype = kCATransitionFromLeft;
    else
        animation.subtype = kCATransitionFromRight;
    
    // Check if there's diary available for selected date
    if([monthModel checkDiaryForDate:_selectedDate]) {
        DiaryData *d = [monthModel.diarysInDate lastObject];
        showDiaryData = d;
        if (d.diaryVideoPath) {
            _diaryImageView.image = d.diaryVideoThumbnail;
            _videoPlayView.hidden = NO;
        }
        else {
            _diaryImageView.image = [d.diaryPhotoThumbnail resizeImageToSize:_diaryImageView.frame.size];
            _videoPlayView.hidden = YES;
        }
        _diaryTitle.text = d.subject;
        _diaryDetail.text = d.diaryText;
        _diaryDate.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated]];
        
        if (d.location.length > 0) {
            _locationTag.hidden = NO;
            _diaryLocation.text = d.location;
        } else {
            _locationTag.hidden = YES;
            _diaryLocation.text = nil;
        }
        _emptyDiaryView.hidden = YES;
        [_diaryView.layer addAnimation:animation forKey:nil];
        _diaryView.hidden = NO;
    } else if (_emptyDiaryView.hidden) {
        _diaryView.hidden = YES;
        [_emptyDiaryView.layer addAnimation:animation forKey:nil];
        _emptyDiaryView.hidden = NO;
    }
}

- (void)resetCalendarBySelectDate:(BOOL)bySelect
{
    [_monthView setAppearanceOnDeselectDate:previousDateModel.date dateNotInCurrentMonth:previousDateModel.isCurrentMonth];
    previousDateModel.isSelected = NO;
    // Reset monthmodel
    [monthModel createMonthWithSelectedDate:_selectedDate];
    // Refresh Month view
    [_monthView setupCalendar:monthModel];
    
    // Adjust selected date to monday of the week if month view is shrinked
    // Weekday Sunday = 1 , Saturday = 6
    if (_monthView.shrink&&!bySelect) {
        NSDateComponents *dateComponents = [_gregorian components:(
                                                                   NSYearCalendarUnit |
                                                                   NSMonthCalendarUnit|
                                                                   NSDayCalendarUnit  |
                                                                   NSWeekdayCalendarUnit |
                                                                   NSWeekOfMonthCalendarUnit
                                                                   )
                                                         fromDate:_selectedDate];
        if ([dateComponents weekday]==1) {
            dateComponents.day -= 6;
        }
        else {
            dateComponents.day -= ([dateComponents weekday]-2);
        }
        _selectedDate = [_gregorian dateFromComponents:dateComponents];
    }
    
    if (_monthView.shrink)
        [self showEventTable];
    else
        [self showComingEvent];
    
    [self showDiary];
    
    // Set up previous date view and model
    previousDateModel = [monthModel dateModelForDate:_selectedDate];
    previousDateModel.isSelected = YES;
    [_monthView setAppearanceOnSelectDate:previousDateModel.date];
    // Activate date view in month view
    [self activateDateLabelGesture];
    
    // Refresh navigation bar
    [self setNavgationBarTitle];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [_monthView.dateGroupView.layer removeAllAnimations];
}

-(void)addDiary
{
    DiaryCreateViewController *dcv = [[DiaryCreateViewController alloc]init];
    [self.navigationController pushViewController:dcv animated:YES];
}

- (void)addEvent
{
    EventCreateController *newEventController = [[EventCreateController alloc]init];
    newEventController.selectedDate = _selectedDate;
    [[self navigationController]pushViewController:newEventController animated:YES];
}

@end
