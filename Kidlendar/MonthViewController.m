//
//  MonthViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "MonthViewController.h"
#import "DateView.h"
#import "EventCreateViewController.h"
#import <EventKit/EventKit.h>
#import "DiaryCreateViewController.h"
#import "DiaryDataStore.h"
#import "DiaryData.h"
#import "MonthModel.h"
#import "DateModel.h"
#import <AddressBook/AddressBook.h>
#import "UIImage+Resize.h"
#import "EventViewController.h"
#import "DiaryCell.h"

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
}

@property (weak, nonatomic) IBOutlet UILabel *comingEventTime;
@property (weak, nonatomic) IBOutlet UILabel *comingEventTitle;
@property (weak, nonatomic) IBOutlet UIView *comingEventView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (weak, nonatomic) IBOutlet UIImageView *diaryImageView;
@property (weak, nonatomic) IBOutlet UIView *dotViewGray;
@property (weak, nonatomic) IBOutlet UILabel *diaryTitle;

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
    
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"MM月dd日 EEEE";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    

    UITapGestureRecognizer *eventTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showEventView)];
    [_comingEventView addGestureRecognizer:eventTap];
    _dotView.layer.cornerRadius = _dotView.frame.size.width/2;
    _dotView.backgroundColor = Rgb2UIColor(251, 106, 119);
    
    _dotViewGray.layer.cornerRadius = _dotView.frame.size.width/2;
    
    self.navigationController.navigationBar.clipsToBounds = YES;
    
    _selectedDate = [monthModel dateModelForDate:[NSDate date]].date;
    [_monthView initCalendar:monthModel];
    [self resetCalendar];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(forwardMonth:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                    action:@selector(rewindMonth:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                 action:@selector(shrinkMonth)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(expandMonth)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    
    [_monthView addGestureRecognizer:swipeLeft];
    [_monthView addGestureRecognizer:swipeRight];
    [_monthView addGestureRecognizer:swipeUp];
    [_monthView addGestureRecognizer:swipeDown];
    

    
     
    // Set up table for events
    eventTableView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    eventTableView.dataSource = self;
    eventTableView.backgroundColor = [UIColor clearColor];
    eventTableView.hidden = YES;
    eventTableView.delegate = self;
    eventTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [eventTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:eventTableView];
    
    // Bar button for adding event
    UIBarButtonItem *addEventButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                   target:self
                                                                                   action:@selector(addEvent)];
    
    UIBarButtonItem *addDiaryButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                   target:self
                                                                                   action:@selector(addDiary)];
    
    self.navigationItem.rightBarButtonItems = @[addEventButton,addDiaryButton];
    
    UIBarButtonItem *monthButton = [[UIBarButtonItem alloc]initWithTitle:@"Month" style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil ];
    
    self.navigationItem.leftBarButtonItem = monthButton;
    
    
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
    
    NSArray *monthArray = @[@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec"];
    NSString *month = monthArray[[comp month]-1];
    [self.navigationItem.leftBarButtonItem setTitle:[NSString stringWithFormat:@"%lu %@",(long)[comp year],month]];
}

#pragma mark - UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    EKEvent *event = monthModel.eventsInDate[indexPath.row];
    cell.textLabel.text = event.title;
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
    return 50;
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
    if (_monthView.shrink)
        [self expandMonth];
    else
        [self resetCalendar];
}

-(void)refreshDiary:(NSNotification *)notification
{
//    [_diaryCollectionView reloadData];
}

- (void)switchEKCalendar:(NSNotification *)notification
{
    // Re construct month model
    monthModel = [[MonthModel alloc]initMonthCalendarWithDate:[NSDate date] andCalendar:_gregorian];
    
    // Refresh calendar view
    [_monthView initCalendar:monthModel];
    
    [self resetCalendar];

}


#pragma mark -UIGesture

-(void)showEventView
{
    EventViewController *evc = [[EventViewController alloc]init];
    evc.event = _comingUpEvent;
    evc.selectedDate = _selectedDate;
    [self.navigationController pushViewController:evc animated:YES];
}

- (void)forwardMonth:(UITapGestureRecognizer *)sender
{
    if (_monthView.shrink)
        [self switchCalendarByWeek:1];
    else
        [self switchCalendarByMonth:1];
}

- (void)rewindMonth:(UITapGestureRecognizer *)sender
{
    if (_monthView.shrink)
        [self switchCalendarByWeek:0];
    else
        [self switchCalendarByMonth:0];
}

- (void)shrinkMonth
{
    if (!_monthView.shrink) {
        eventTableView.hidden = NO;
        _comingEventView.hidden = YES;
//        _diaryCollectionView.hidden = YES;
        _monthView.shrink = YES;
        [self showEventTable];
    }
}

-(void)expandMonth
{
    if (_monthView.shrink) {
        eventTableView.hidden = YES;
        _comingEventView.hidden = NO;
//        _diaryCollectionView.hidden = NO;
        _monthView.shrink = NO;
        [self resetCalendar];
    }
}

- (void)switchCalendarByMonth:(int)forwardOrRewind
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

    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionReveal;
    DateModel *selectedDateModel = [monthModel dateModelForDate:_selectedDate];
    // Rewind = 0 , Forward = 1
    if (forwardOrRewind==0) {
        transition.subtype = kCATransitionFromLeft;
        if (selectedDateModel.isCurrentMonth)
            [dateComponents setMonth:([dateComponents month] - 1)];
    }
    else {
        transition.subtype = kCATransitionFromRight;
        if (selectedDateModel.isCurrentMonth)
            [dateComponents setMonth:([dateComponents month] + 1)];
    }
    
    // Set _selected date to 1st date of previous/next month
    dateComponents.day = 1;
    _selectedDate = [_gregorian dateFromComponents:dateComponents];
    [self resetCalendar];
}

- (void)switchCalendarByWeek:(int)forwardOrRewind
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

    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionReveal;
    DateModel *selectedDateModel = [monthModel dateModelForDate:_selectedDate];

    // Rewind = 0 , Forward = 1
    if (forwardOrRewind==0) {
        transition.subtype = kCATransitionFromLeft;
        row = row - 1;
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
    else {
        transition.subtype = kCATransitionFromRight;
        row = row + 1;
        DateModel *d = [monthModel.datesInMonth lastObject];
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
    [self resetCalendar];
    [self.monthView.layer addAnimation:transition forKey:nil];
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
    // Set up position of event & diary detail view
    [_monthView setAppearanceOnSelectDate:dateModel.date];
    previousDateModel = dateModel;
    
    if (_monthView.shrink)
        [self showEventTable];
    else
        [self showComingEvent];
}

- (void)activateDateLabelGesture
{
    for (DateView *subview in [_monthView subviews]) {
        if (subview.row > -1) {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(dateLabelTap:)];
            [subview addGestureRecognizer:tapGesture];
        }
    }
}

- (void)showEventTable
{
    [monthModel checkEventForDate:_selectedDate];
    [_monthView shrinkCalendarWithRow:[monthModel rowNumberForDate:_selectedDate]];

    // Opens event and diary details on tap date
    eventTableView.frame = CGRectMake(0, _monthView.frame.origin.y+_monthView.frame.size.height, self.view.frame.size.width, 200);
    [eventTableView reloadData];
}

- (void)showComingEvent
{

    NSDateFormatter *onlydateFormatter = [[NSDateFormatter alloc]init];
    onlydateFormatter.dateFormat = @"hh:mm aa";
    onlydateFormatter.timeZone = [NSTimeZone systemTimeZone];

    [monthModel checkEventForDate:_selectedDate];
    if ([monthModel.eventsInDate count]> 0) {
        for (EKEvent *comingUpEvent in monthModel.eventsInDate) {
            if (comingUpEvent.startDate >[NSDate date]) {
                _comingUpEvent = comingUpEvent;
//                _comingEventTime.text = [timeFormatter stringFromDate:comingUpEvent.startDate];
//                _comingEventDate.text = [dateFormatter stringFromDate:comingUpEvent.startDate];
                
                _comingEventTime.text  = [onlydateFormatter stringFromDate:comingUpEvent.startDate];
                
                _comingEventTitle.text = comingUpEvent.title;
                _locationLabel.text = comingUpEvent.location;
                break;
            }
        }
    }
   else {
        _comingEventTime.text = nil;
        _comingEventTitle.text = nil;
    }
}

-(void)showDiary
{
    // Check if there's diary available
    DiaryData *d = [[DiaryDataStore sharedStore]allItems][0];
    _diaryImageView.image = d.diaryImage;
    _diaryTitle.text = d.diaryText;
}

- (void)resetCalendar
{
    [_monthView setAppearanceOnDeselectDate:previousDateModel.date dateNotInCurrentMonth:previousDateModel.isCurrentMonth];
    previousDateModel.isSelected = NO;
    // Reset monthmodel
    [monthModel createMonthWithSelectedDate:_selectedDate];
    // Refresh Month view
    [_monthView setupCalendar:monthModel];
    
    // Adjust selected date to monday of the week if month view is shrinked
    // Weekday Sunday = 1 , Saturday = 6
    if (_monthView.shrink) {
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
    
    // Set up previous date view and model
    previousDateModel = [monthModel dateModelForDate:_selectedDate];
    previousDateModel.isSelected = YES;
    [_monthView setAppearanceOnSelectDate:previousDateModel.date];
    // Activate date view in month view
    [self activateDateLabelGesture];
    // Refresh navigation bar
    [self setNavgationBarTitle];
    
    if (_monthView.shrink)
        [self showEventTable];
    else
        [self showComingEvent];
}

-(void)addDiary
{
    DiaryCreateViewController *dcv = [[DiaryCreateViewController alloc]init];
    dcv.diary = [[DiaryDataStore sharedStore]createItem];
    [self.navigationController pushViewController:dcv animated:YES];
}

- (void)addEvent
{
    EventCreateViewController *newEventController = [[EventCreateViewController alloc]init];
    newEventController.selectedDate = _selectedDate;
    [[self navigationController]pushViewController:newEventController animated:YES];
}

@end
