//
//  EventCreateController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventCreateController.h"
#import "CalendarStore.h"
#import "ReminderView.h"
#import "RepeatView.h"
#import <EventKit/EventKit.h>
#import "ReminderButton.h"
#import "LocationData.h"
#import "SelectedLocation.h"
#import "LocationDataStore.h"
#import "MapViewController.h"
#import "Reachability.h"

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"

@interface EventCreateController () <UITextFieldDelegate,UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate,UIPickerViewDelegate,UIPickerViewDataSource>
{
    EKEvent *event;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    NSDate *minimumDate;
    ReminderView *reminder;
    RepeatView *repeat;
    EKAlarm *alarm;
    EKRecurrenceRule *recurrenceRule;
    NSArray *places;
    SelectedLocation *selectedLocation;
    CGRect saveButtonFrame;
    CGRect saveButtonFrameMove;
    EKCalendar *selectedCalendar;
    CLLocationCoordinate2D destination;
    UIView *toolView;
    NSMutableArray *writableCalendars;
}

@property (weak, nonatomic) IBOutlet UITextField *subjectField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *endTimeField;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UIView *eventDetailView;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *alldayView;
@property (weak, nonatomic) IBOutlet UILabel *allLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UIView *startTimeView;
@property (weak, nonatomic) IBOutlet UIView *endTimeView;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatValueLabel;
@property (weak, nonatomic) IBOutlet UITextField *calendarNameField;
@property (weak, nonatomic) IBOutlet UILabel *calenderNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *calendarLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mapIcon;
@property (weak, nonatomic) IBOutlet UIImageView *locationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reminderImageView;
@property (weak, nonatomic) IBOutlet UIImageView *repeatImageView;
@property (weak, nonatomic) IBOutlet UIImageView *calendarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *startTimeArrow;
@property (weak, nonatomic) IBOutlet UITextField *reminderTextField;
@property (weak, nonatomic) IBOutlet UITextField *repeatTextField;

@end

@implementation EventCreateController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Navgition bar
    self.navigationItem.title = @"New Event";
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    toolView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    toolView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    
    UIView *topBorder = [[UIView alloc]initWithFrame:CGRectMake(0, 40, 320, 1)];
    topBorder.backgroundColor = [UIColor colorWithWhite:0.902 alpha:1.000];
    [toolView addSubview:topBorder];
    
    UIButton *saveButton = [[UIButton alloc]initWithFrame:CGRectMake(320-42.5, 1.5, 35, 35)];
    saveButton.backgroundColor = MainColor;
    [saveButton setImage:[UIImage imageNamed:@"save.png"] forState:UIControlStateNormal];
    saveButton.layer.cornerRadius = saveButton.frame.size.width/2;
    [saveButton addTarget:self action:@selector(saveEvent:) forControlEvents:UIControlEventTouchDown];
    [toolView addSubview:saveButton];
    
    _locationSearchBar.delegate = self;
    _locationSearchBar.tintColor = MainColor;
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    
    _locationSearchView.layer.cornerRadius = 10.0f;

    // Calendar
    _calenderNameLabel.text = [[[[CalendarStore sharedStore]selectedCalendars]objectAtIndex:0]title];
    UIPickerView *calendarPicker = [[UIPickerView alloc]init];
    calendarPicker.delegate = self;
    calendarPicker.dataSource = self;

    _calendarNameField.delegate = self;
    _calendarNameField.tintColor = [UIColor clearColor];
    _calendarNameField.inputView = calendarPicker;

    // Reminder selection view
    reminder = [[ReminderView alloc]init];
    for (UIView *b in reminder.subviews) {
        if ([b isKindOfClass:[ReminderButton class]])
            [(ReminderButton *)b addTarget:self action:@selector(alarmTap:) forControlEvents:UIControlEventTouchDown];
    }
    _reminderTextField.delegate = self;
    _reminderTextField.inputView = reminder;
    _reminderTextField.tintColor = [UIColor clearColor];
    
    // Repeat selection view
    repeat = [[RepeatView alloc]init];
    for (UIView *b in repeat.subviews) {
        if ([b isKindOfClass:[ReminderButton class]])
            [(ReminderButton *)b addTarget:self action:@selector(recurrenceBtn:) forControlEvents:UIControlEventTouchDown];
    }
    _repeatTextField.delegate = self;
    _repeatTextField.inputView = repeat;
    _repeatTextField.tintColor = [UIColor clearColor];

    // Set up All Day button
    _alldayView.layer.borderColor = [LightGrayColor CGColor];
    _alldayView.layer.borderWidth = 1.0f;
    UITapGestureRecognizer *alldayTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(alldayAction)];
    [_alldayView addGestureRecognizer:alldayTap];
    
    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
//    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Set up time formatter
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"hh:mm aa";
//    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Setup Date picker
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [_datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    _datePicker.minuteInterval = 5;
    _datePicker.date = _selectedDate;
    
    // When enter bring up title and time view and keyboard
    _subjectField.delegate = self;
    _locationField.delegate = self;
    _locationField.tag = 3;
    
    _startTimeField.delegate = self;
    _startTimeField.inputView = _datePicker;
    _startTimeField.tintColor = [UIColor clearColor];
    _endTimeField.delegate = self;
    _endTimeField.inputView = _datePicker;
    _endTimeField.tintColor = [UIColor clearColor];
    
    _startTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_selectedDate]];
    _startDateLabel.text = [dateFormatter stringFromDate:_selectedDate];
    
    _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:[NSDate dateWithTimeInterval:3600 sinceDate:_selectedDate]]];
    _endDateLabel.text =  [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:3600 sinceDate:_selectedDate]];
    
    minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_selectedDate];
    _datePicker.minimumDate = minimumDate;
    
    // Initialize new event
    event = [EKEvent eventWithEventStore:[[CalendarStore sharedStore]eventStore]];
//    event.timeZone = [NSTimeZone systemTimeZone];
    event.calendar = [[[CalendarStore sharedStore]selectedCalendars]objectAtIndex:0];
    event.startDate = _selectedDate;
    event.endDate = [NSDate dateWithTimeInterval:3600 sinceDate:_selectedDate];
    event.allDay = NO;
    [event addAlarm:[EKAlarm alarmWithRelativeOffset:-60*15]];
    [self checkAlarm];
    
    selectedLocation = [[SelectedLocation alloc]init];
    
    // Map icon
    UITapGestureRecognizer *mapIconTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMap)];
    [_mapIcon addGestureRecognizer:mapIconTap];
    
    writableCalendars = [[NSMutableArray alloc]init];
    for (EKCalendar *cal in [[CalendarStore sharedStore]allCalendars]) {
        if (cal.allowsContentModifications) {
            [writableCalendars addObject:cal];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    [_subjectField becomeFirstResponder];

}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showMap
{
    if ([self checkInternetConnection]) {
        MapViewController *map = [[MapViewController alloc]initWithLocation:selectedLocation];
        [self.navigationController pushViewController:map animated:YES];
    }
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [writableCalendars count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    EKCalendar *calendar = writableCalendars[row];
    return calendar.title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectedCalendar = writableCalendars[row];
    _calenderNameLabel.text = selectedCalendar.title;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Tag 0 = title , 1 = startTime , 2 = endTime , 3 = locatoin , 4 = reminder , 5 = repeat , 6 = calenda
    [self hideAllImage];
    switch (textField.tag) {
        case 1:
            _datePicker.minimumDate = nil;
            [_datePicker setDate:event.startDate];
            _startTimeView.backgroundColor = MainColor;
            _startDateLabel.textColor = [UIColor whiteColor];
            _startTimeLabel.textColor = [UIColor whiteColor];
            _startTimeArrow.hidden = NO;
            break;
        case 2:
            [_datePicker setDate:event.endDate];
            _endTimeView.backgroundColor = MainColor;
            _endTimeLabel.textColor = [UIColor whiteColor];
            _endDateLabel.textColor = [UIColor whiteColor];
            _startTimeArrow.hidden = YES;
            break;
        default:
            break;
    }
    if (textField.tag >2)
        [self showImage:textField.tag];

    textField.inputView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    textField.inputAccessoryView = toolView;
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField.tag == 3)
        _mapIcon.hidden = YES;
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField.tag == 3)
        _mapIcon.hidden = YES;
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 1:
            _startTimeView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
            _startDateLabel.textColor = [UIColor blackColor];
            _startTimeLabel.textColor = [UIColor blackColor];
            _startTimeArrow.hidden = YES;
            _datePicker.minimumDate = minimumDate;
            break;
        case 2:
            _endTimeView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
            _endDateLabel.textColor = LightGrayColor;
            _endTimeLabel.textColor = LightGrayColor;
            break;
        default:
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeySearch) {
        if ([self checkInternetConnection]) {
            _locationSearchBar.text = _locationField.text;
            
            // Start searching from google when search key is pressed
            [self queryGooglePlaces:_locationField.text];
            
            // Show the search table and search bar
            _maskView.hidden = NO;
            [_locationSearchBar becomeFirstResponder];
            return YES;
        } else
            return NO;
    }
    return YES;
}

#pragma mark - User actions
-(void)changeDate
{
    if (!event.allDay) {
        if (_startTimeField.isFirstResponder) {
            _startDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            _startTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate: _datePicker.date]];
            event.startDate = _datePicker.date;
            
            // Minimum end time after start time is selected
            minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_datePicker.date];
            event.endDate = [NSDate dateWithTimeInterval:3600 sinceDate:_datePicker.date];
            _endDateLabel.text = [dateFormatter stringFromDate:event.endDate];
            _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:event.endDate]];
        }
        else {
            _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate: _datePicker.date]];
            _endDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            event.endDate = _datePicker.date;
        }
    }
    else {
        if (_startTimeField.isFirstResponder) {
            _startDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            event.startDate = _datePicker.date;

            minimumDate = _datePicker.date;

            _endDateLabel.text = [dateFormatter stringFromDate:minimumDate];
            event.endDate = minimumDate;
        }
        else {
            _endDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            event.endDate = _datePicker.date;
        }
    }
}

- (void)showImage:(NSInteger)tag
{
    switch (tag) {
        case 3:
            // Location
            [self showLocation];
            break;
        case 4:
            // Reminder
            [self showReminder];
            break;
        case 5:
            // Repeat
            [self showRepeat];
            break;
        case 6:
            // Calendar
            [self showCalendar];
            break;
        default:
            break;
    }
}

- (void)hideAllImage
{
    [self hideLocation];
    [self hideReminder];
    [self hideRepeat];
    [self hideCalendar];
}

// Show

- (void)showCalendar
{
    _calendarImageView.image = [UIImage imageNamed:@"eventCalendarFill20.png"];
    _calenderNameLabel.textColor = MainColor;
    _calendarLabel.textColor = MainColor;
}

- (void)showRepeat
{
    _repeatImageView.image = [UIImage imageNamed:@"eventRepeatFill20.png"];
    _repeatLabel.textColor = MainColor;
    _repeatValueLabel.textColor = MainColor;
}

- (void)showReminder
{
    _reminderImageView.image = [UIImage imageNamed:@"eventReminderFill20.png"];
    _reminderLabel.textColor = MainColor;
    _reminderValueLabel.textColor = MainColor;
}

- (void)showLocation
{
    _locationImageView.image = [UIImage imageNamed:@"eventLocationFill20.png"];
}

// Hide

- (void)hideCalendar
{
    _calendarImageView.image = [UIImage imageNamed:@"eventCalendarLine20.png"];
    _calenderNameLabel.textColor = LightGrayColor;
    _calendarLabel.textColor = LightGrayColor;
}

- (void)hideRepeat
{
    _repeatImageView.image = [UIImage imageNamed:@"eventRepeatLine20.png"];
    _repeatValueLabel.textColor = LightGrayColor;
    _repeatLabel.textColor = LightGrayColor;
}

- (void)hideReminder
{
    _reminderImageView.image = [UIImage imageNamed:@"eventReminderLine20.png"];
    _reminderValueLabel.textColor = LightGrayColor;
    _reminderLabel.textColor = LightGrayColor;
}

- (void)hideLocation
{
    _locationImageView.image = [UIImage imageNamed:@"eventLocationLine20.png"];
}

- (void)saveEvent:(id)sender
{
    // Create new event
    event.title = _subjectField.text;
    event.location = _locationField.text;
    [[[CalendarStore sharedStore]eventStore] saveEvent:event span:EKSpanThisEvent commit:YES error:nil];
    
    
    NSLog(@"id %@",event.eventIdentifier);
    // Create new location
    if (selectedLocation.locationName) {
        LocationData *eventLocation = [[LocationDataStore sharedStore]createItemWithKey:event.eventIdentifier];
        eventLocation.latitude = selectedLocation.latitude;
        eventLocation.longitude = selectedLocation.longitude;
        eventLocation.locationName = selectedLocation.locationName;
        eventLocation.locationAddress = selectedLocation.locationAddress;
        eventLocation.reference = selectedLocation.reference;
        [[LocationDataStore sharedStore]saveChanges];
    }
    
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)searchLocation
{
    _locationSearchBar.text = _locationField.text;
    [self queryGooglePlaces:_locationField.text];
    _maskView.hidden = NO;
}

- (void)alldayAction
{
    [self hideAllImage];

    if (event.allDay) {
        event.allDay = NO;
        _alldayView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
        _alldayView.layer.borderWidth = 1.0f;
        _allLabel.textColor = LightGrayColor;
        _dayLabel.textColor = LightGrayColor;
        
        _startDateLabel.frame = CGRectOffset(_startDateLabel.frame, 0, 13);
        _endDateLabel.frame = CGRectOffset(_endDateLabel.frame, 0 , 13);
        _startDateLabel.font = [UIFont systemFontOfSize:13];
        _endDateLabel.font = [UIFont systemFontOfSize:13];
        
        _startTimeLabel.hidden = NO;
        _endTimeLabel.hidden = NO;
        
        _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        _datePicker.minuteInterval = 5;


    } else {
        event.allDay = YES;
        _alldayView.backgroundColor = MainColor;
        _alldayView.layer.borderWidth = 0.0f;
        _allLabel.textColor = [UIColor whiteColor];
        _dayLabel.textColor = [UIColor whiteColor];
        
        _startDateLabel.frame = CGRectOffset(_startDateLabel.frame, 0 , -13);
        _endDateLabel.frame = CGRectOffset(_endDateLabel.frame, 0 , -13);
        _startDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        _endDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        
        _startTimeLabel.hidden = YES;
        _endTimeLabel.hidden = YES;
        
        _datePicker.datePickerMode = UIDatePickerModeDate;
    }
}

- (void)createEvent
{
    event.title = _subjectField.text;
    NSError *err;
    [[[CalendarStore sharedStore]eventStore] saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Reminder

- (void)checkAlarm
{
    if (event.hasAlarms) {
        for (EKAlarm *a in event.alarms) {
            for (ReminderButton *b in reminder.subviews) {
                if ((b.tag==1&&a.absoluteDate)||(b.timeOffset == a.relativeOffset*-1)) {
                    [b setSelected:YES];
                    b.backgroundColor =MainColor;
                    _reminderValueLabel.text = [b.titleLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                    break;
                }
            }
        }
    } else {
        _reminderValueLabel.text = @"No Reminder";
    }
}

- (void)removeAllAlarms
{
    if (event.hasAlarms) {
        for (EKAlarm *a in event.alarms) {
            [event removeAlarm:a];
        }
    }
}

- (void)alarmTap:(UIButton *)sender
{
    // Tag : 1 - on time , 2 - 5min , 3 - 15min , 4 - 30min , 5 - 1hour , 6 - 2hour ,7 - 1day , 8 - 2Day , 9 - 1week
    if([sender isSelected]){
        [sender setSelected:NO];
        if (sender.tag < 10)
            sender.backgroundColor = [UIColor clearColor];
    } else {
        [sender setSelected:YES];
        if (sender.tag < 10) {
            sender.backgroundColor = MainColor;
            [self createAlarm:sender.tag];
            _reminderValueLabel.text = [sender.titleLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        }
        
        // Change all other buttons to unselect
        for (ReminderButton *b in reminder.subviews) {
            if (b.tag < 10 && b.tag != sender.tag) {
                [b setSelected:NO];
                b.backgroundColor = [UIColor clearColor];
            }
        }
    }
}

- (void)createAlarm:(NSInteger)i
{
    switch (i) {
        case 1:
            alarm = [EKAlarm alarmWithAbsoluteDate:event.startDate];
            break;
        case 2:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*5];
            break;
        case 3:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*15];
            break;
        case 4:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*30];
            break;
        case 5:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60];
            break;
        case 6:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*120];
            break;
        case 7:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24];
            break;
        case 8:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24*2];
            break;
        case 9:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24*7];
            break;
        default:
            break;
    }
    [self removeAllAlarms];
    [event addAlarm:alarm];
}

- (NSString *)minuteToString:(NSInteger)minute
{
    NSString *time;
    switch (minute/-1) {
        case 0:
            time = @"On Time";
            break;
        case 300:
            time = @"5 Min";
            break;
        case 900:
            time = @"15 Min";
            break;
        case 1800:
            time = @"30 Min";
            break;
        case 3600:
            time = @"1 Hour";
            break;
        case 7200:
            time = @"2 Hours";
            break;
        case 86400:
            time = @"1 Day";
            break;
        case 172800:
            time = @"2 Days";
            break;
        case 604800:
            time = @"1 Week";
            break;
        default:
            break;
    }
    
    return time;
}


#pragma mark - Repeat

- (void)recurrenceBtn:(UIButton *)sender
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    if([sender isSelected]){
        [sender setSelected:NO];
        if (sender.tag < 10)
            sender.backgroundColor = [UIColor clearColor];
        
    } else {
        [sender setSelected:YES];
        if (sender.tag < 10) {
            sender.backgroundColor = MainColor;
            [self createRule:sender.tag];
            _repeatValueLabel.text = sender.titleLabel.text;
        }
        
        // Change all other buttons to unselect
        for (UIButton *b in repeat.subviews) {
            if (b.tag < 10 && b.tag != sender.tag) {
                [b setSelected:NO];
                b.backgroundColor = [UIColor clearColor];
            }
        }
    }
}

- (void)removeAllRules
{
    if (event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in event.recurrenceRules) {
            [event removeRecurrenceRule:r];
        }
    }
}

- (void)createRule:(NSInteger )tag
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    switch (tag) {
        case 1:
            // Does nothing
            break;
        case 2:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil];
            break;
        case 3:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil];
            break;
        case 4:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:2 end:nil];
            break;
        case 5:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly interval:1 end:nil];
            break;
        case 6:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyYearly interval:1 end:nil];
            break;
        default:
            break;
    }
    [self removeAllRules];
    if (recurrenceRule)
        [event addRecurrenceRule:recurrenceRule];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _locationField.text = searchBar.text;
    [self queryGooglePlaces:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _maskView.hidden = YES;
    [_locationField becomeFirstResponder];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    // Show the search result
    NSString *locName = [places[indexPath.row] objectForKey:@"name"];
    NSString *address = [places[indexPath.row] objectForKey:@"formatted_address"];
    
    cell.textLabel.text = locName;
    cell.detailTextLabel.text = address;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [places count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _locationField.text = [places[indexPath.row] objectForKey:@"name"];
    [_locationField becomeFirstResponder];
    
    // Create temp location data
    NSDictionary *selectedPlace = [places objectAtIndex:indexPath.row];
    selectedLocation.latitude =  [[[[selectedPlace objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
    selectedLocation.longitude = [[[[selectedPlace objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
    selectedLocation.locationName = [selectedPlace objectForKey:@"name"];
    selectedLocation.locationAddress = [selectedPlace objectForKey:@"formatted_address"];
    selectedLocation.reference = [selectedPlace objectForKey:@"reference"];
    
    // Hide search table after row selected
    _maskView.hidden = YES;
    _mapIcon.hidden = NO;
}

#pragma mark - Google Places Search

-(void) queryGooglePlaces:(NSString *)name
{
    // Sensor = true means search using GPS
    NSString *url;
    url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&sensor=true&language=zh-TW&key=%@",name,kGOOGLE_API_KEY];
    
    //Formulate the string as a URL object.
    NSURL *googleRequestURL=[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // Retrieve the results of the URL.
    
    NSURLRequest *request = [NSURLRequest requestWithURL:googleRequestURL];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if ([data length]>0 && connectionError==nil) {
                                   //收到正確的資料，連線沒有錯
                                   NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:NSJSONReadingAllowFragments
                                                                                          error:&connectionError];
                                   //The results from Google will be an array obtained from the NSDictionary object with the key "results".
                                   places = [json objectForKey:@"results"];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [_searchResultTable reloadData];
                                   });
                                   
                               } else if ([data length]==0 && connectionError==nil) {
                                   //沒有資料，連線沒有錯誤
                               } else if (connectionError != nil) {
                                   //連線有錯誤
                                   NSLog(@"error %@",connectionError);
                               }
                           }];
}

- (BOOL)checkInternetConnection
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *noInternetAlert = [[UIAlertView alloc]initWithTitle:@"No Internet Connection"
                                                                 message:@"Check your internet and try again"
                                                                delegate:self cancelButtonTitle:@"Close"
                                                       otherButtonTitles:nil, nil];
        [noInternetAlert show];
        return NO;
    } else {
        return YES;
    }
}

- (NSAttributedString *)attributedTimeText:(NSString *)timeString
{
    NSMutableAttributedString *newTimeString = [[NSMutableAttributedString alloc] initWithString:timeString];

    if (timeString.length > 6) {
        
        NSRange selectedRange = NSMakeRange(5, 3);
        
        [newTimeString beginEditing];
        [newTimeString addAttribute:NSFontAttributeName
                              value:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0]
                              range:selectedRange];
        [newTimeString endEditing];
    }
    return newTimeString;
}

@end
