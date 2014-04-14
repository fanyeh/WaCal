//
//  EventReviewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventReviewController.h"
#import "CalendarStore.h"
#import "ImageStore.h"
#import "LocationDataStore.h"
#import "LocationData.h"
#import "SelectedLocation.h"
#import <MapKit/MapKit.h>
#import "MapKitHelpers.h"
#import "ReminderView.h"
#import "RepeatView.h"
#import "ReminderButton.h"
#import "MapViewController.h"
#import "Reachability.h"

#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"

typedef void (^LocationCallback)(CLLocationCoordinate2D);

@interface EventReviewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UISearchBarDelegate,MKMapViewDelegate,UIAlertViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;

    BOOL hasDestination;

    NSDate *minimumDate;
    ReminderView *reminder;
    RepeatView *repeat;
    EKAlarm *alarm;
    EKRecurrenceRule *recurrenceRule;
    NSArray *places;
    
    SelectedLocation *selectedLocation;
    
    EKCalendar *selectedCalendar;
    CGRect saveButtonFrame;
    CGRect saveButtonFrameMove;
    
    CGRect trashButtonFrame;
    CGRect trashButtonFrameMove;
    UIView *toolView;
    
    BOOL isAllDay;
    
    NSDate *eventStartDate;
    NSDate *eventEndDate;
    
    NSMutableArray *writableCalendars;
}

@property (weak, nonatomic) IBOutlet UILabel *calendarLabel;
@property (weak, nonatomic) IBOutlet UITextField *subjectField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;

@property (weak, nonatomic) IBOutlet UIView *startTimeView;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;

@property (weak, nonatomic) IBOutlet UIView *endTimeView;
@property (weak, nonatomic) IBOutlet UITextField *endTimeField;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;

@property (weak, nonatomic) IBOutlet UIView *eventDetailView;

@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;

@property (weak, nonatomic) IBOutlet UIView *alldayView;
@property (weak, nonatomic) IBOutlet UILabel *allLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;

@property (weak, nonatomic) IBOutlet UILabel *calendarName;
@property (weak, nonatomic) IBOutlet UITextField *calendarNameField;

@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderLabel;
@property (weak, nonatomic) IBOutlet UILabel *reminderValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *repeatValueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *mapIcon;
@property (weak, nonatomic) IBOutlet UIImageView *locationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reminderImageView;
@property (weak, nonatomic) IBOutlet UIImageView *repeatImageView;
@property (weak, nonatomic) IBOutlet UIImageView *calendarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *startTimeArrow;
@property (weak, nonatomic) IBOutlet UITextField *reminderTextField;
@property (weak, nonatomic) IBOutlet UITextField *repeatTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startDateFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *endDateFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startDateConstraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *endDateConstraintTop;

@end

@implementation EventReviewController

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
    
    // View controller
    self.navigationItem.title = @"Event Details";
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
    [saveButton addTarget:self action:@selector(saveEvent) forControlEvents:UIControlEventTouchDown];
    [toolView addSubview:saveButton];
    
    UIButton *deleteButton = [[UIButton alloc]initWithFrame:CGRectMake(7.5, 1.5, 35, 35)];
    deleteButton.backgroundColor = TodayColor;
    [deleteButton setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    deleteButton.layer.cornerRadius = deleteButton.frame.size.width/2;
    [deleteButton addTarget:self action:@selector(deleteEvent:) forControlEvents:UIControlEventTouchDown];
    [toolView addSubview:deleteButton];

    // Calendar
    _calendarName.text = _event.calendar.title;
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

    [self checkAlarm];
    _reminderTextField.delegate = self;
    _reminderTextField.inputView = reminder;
    _reminderTextField.tintColor = [UIColor clearColor];
    
    // Repeat selection view
    repeat = [[RepeatView alloc]init];
    for (UIView *b in repeat.subviews) {
        if ([b isKindOfClass:[ReminderButton class]])
            [(ReminderButton *)b addTarget:self action:@selector(recurrenceBtn:) forControlEvents:UIControlEventTouchDown];
    }
    [self checkRule];
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
    timeFormatter.dateFormat =  @"hh:mm aa";
//    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Setup Date picker
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [_datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
//    _datePicker.date = _selectedDate;
    
    // When enter bring up title and time view and keyboard
    _subjectField.delegate = self;
    [_subjectField becomeFirstResponder];
    _locationField.delegate = self;
    
    _startTimeField.delegate = self;
    _startTimeField.inputView = _datePicker;
    _startTimeField.tintColor = [UIColor clearColor];
    _endTimeField.delegate = self;
    _endTimeField.inputView = _datePicker;
    _endTimeField.tintColor = [UIColor clearColor];
    
    // Search
    _locationSearchBar.delegate = self;
    _locationSearchBar.tintColor = MainColor;
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    _locationSearchView.layer.cornerRadius = 10.0f;
    
    // Map icon
    UITapGestureRecognizer *mapIconTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMap)];
    [_mapIcon addGestureRecognizer:mapIconTap];
    selectedLocation = [[SelectedLocation alloc]init];
    
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
    
    // Refresh label content based on event
    _subjectField.text = _event.title;
    
    // Refresh event time
    
    _endDateLabel.text =  [dateFormatter stringFromDate:_event.endDate];
    _startDateLabel.text = [dateFormatter stringFromDate:_event.startDate];

    minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_event.startDate];
    _datePicker.minimumDate = minimumDate;
    
    if (_event.allDay) {
        isAllDay = YES;
        _alldayView.backgroundColor = MainColor;
        _alldayView.layer.borderWidth = 0.0f;
        _allLabel.textColor = [UIColor whiteColor];
        _dayLabel.textColor = [UIColor whiteColor];
        
        _startDateFieldConstraint.constant =14;
        _startDateConstraintTop.constant = 15;
        [_startDateLabel needsUpdateConstraints];
        
        _endDateFieldConstraint.constant =14;
        _endDateConstraintTop.constant = 15;
        [_endDateLabel needsUpdateConstraints];

        _startDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        _endDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        
        _startTimeLabel.hidden = YES;
        _endTimeLabel.hidden = YES;
        
        _datePicker.datePickerMode = UIDatePickerModeDate;
        _datePicker.date = [NSDate dateWithTimeInterval:28800 sinceDate:_event.startDate];
        
        eventStartDate = [NSDate dateWithTimeInterval:28800 sinceDate:_event.startDate];
        eventEndDate = [NSDate dateWithTimeInterval:-53999 sinceDate:_event.endDate];
        
        _startTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:eventStartDate]];
        _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:eventEndDate]];

    } else {
        isAllDay = NO;
        _allLabel.textColor = LightGrayColor;
        _dayLabel.textColor = LightGrayColor;
        
        _startTimeLabel.attributedText =[self attributedTimeText:[timeFormatter stringFromDate:_event.startDate]];
        _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_event.endDate]];
        
        eventStartDate = _event.startDate;
        eventEndDate = _event.endDate;
        
        _datePicker.minuteInterval = 5;
    }
    
    
    // Check if there is location
    if (selectedLocation.locationName) {
        _locationField.text = selectedLocation.locationName;
        _mapIcon.hidden = NO;
    }
    else if (_event.location) {
        _locationField.text = _event.location;
        LocationData *l = [[[LocationDataStore sharedStore]allItems]objectForKey:_event.eventIdentifier];
        if (l) {
            selectedLocation.locationName = l.locationName;
            selectedLocation.locationAddress = l.locationAddress;
            selectedLocation.reference = l.reference;
            selectedLocation.latitude = l.latitude;
            selectedLocation.longitude = l.longitude;
            _mapIcon.hidden = NO;
        } else {
            _mapIcon.hidden = YES;
        }
    }
    else {
        _locationField.placeholder = @"Select location";
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
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
    _calendarName.text = selectedCalendar.title;
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIAlertViewDelegate
// Alert before delete event
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex!=0) {
        NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
        NSError *err;
        if (buttonIndex==1)
            [[[CalendarStore sharedStore]eventStore] removeEvent:_event span:EKSpanThisEvent commit:YES error:&err];
        else if (buttonIndex==2)
            [[[CalendarStore sharedStore]eventStore] removeEvent:_event span:EKSpanFutureEvents commit:YES error:&err];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Tag 0 = title , 1 = startTime , 2 = endTime , 3 = locatoin , 4 = reminder , 5 = repeat , 6 = calendar
    [self hideAllImage];
    switch (textField.tag) {
        case 1:
            _datePicker.minimumDate = nil;
            [_datePicker setDate:eventStartDate];
            _startTimeView.backgroundColor = MainColor;
            _startDateLabel.textColor = [UIColor whiteColor];
            _startTimeLabel.textColor = [UIColor whiteColor];
            _startTimeArrow.hidden = NO;
            break;
        case 2:
            [_datePicker setDate:eventEndDate];
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
    [self hideCalendar];
    [self hideReminder];
    [self hideRepeat];
    [self hideLocation];
}

// Show

- (void)showCalendar
{
    _calendarImageView.image = [UIImage imageNamed:@"eventCalendarFill20.png"];
    _calendarName.textColor = MainColor;
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
    _calendarName.textColor = LightGrayColor;
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

- (void)saveEvent
{
    // update event
    NSString *eventIdentifier;
    
    // If use save event to alternate calendar then delete original event and create new event with selected calendar
    if (![selectedCalendar.calendarIdentifier isEqualToString:_event.calendarItemIdentifier] && selectedCalendar) {
        EKEvent  *newEvent = [EKEvent eventWithEventStore:[[CalendarStore sharedStore]eventStore]];
        newEvent.timeZone = [NSTimeZone systemTimeZone];
        newEvent.title = _event.title;
        newEvent.calendar = selectedCalendar;
        newEvent.startDate = _event.startDate;
        newEvent.endDate = _event.endDate;
        newEvent.allDay = isAllDay;
        newEvent.alarms = _event.alarms;
        newEvent.startDate = eventStartDate;
        newEvent.endDate = eventEndDate;
        newEvent.recurrenceRules = _event.recurrenceRules;
        [[[CalendarStore sharedStore]eventStore] saveEvent:newEvent span:EKSpanThisEvent commit:YES error:nil];
        eventIdentifier = newEvent.eventIdentifier;
        
        [[[CalendarStore sharedStore]eventStore] removeEvent:_event span:EKSpanThisEvent commit:YES error:nil];
        
    } else {
        _event.title = _subjectField.text;
        _event.location = _locationField.text;
        _event.allDay = isAllDay;
        _event.startDate = eventStartDate;
        _event.endDate = eventEndDate;

        [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
        eventIdentifier = _event.eventIdentifier;
    }
    
    // Create new location if there isn't one, else update it
    LocationData * eventLocation = [[[LocationDataStore sharedStore]allItems] objectForKey:eventIdentifier];
    if (!eventLocation) {
        eventLocation = [[LocationDataStore sharedStore]createItemWithKey:eventIdentifier];
    }
    
    // Create new location
    if (selectedLocation.locationName) {
        eventLocation.latitude = selectedLocation.latitude;
        eventLocation.longitude = selectedLocation.longitude;
        eventLocation.locationName = selectedLocation.locationName;
        eventLocation.locationAddress = selectedLocation.locationAddress;
        eventLocation.reference = selectedLocation.reference;
        [[LocationDataStore sharedStore]saveChanges];
    }

    NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteEvent:(id)sender
{
    UIAlertView *deleteAlert;
    if (_event.hasRecurrenceRules) {
        deleteAlert = [[UIAlertView alloc]initWithTitle:@"Delete Event"
                                                message:nil
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Delete current event",@"Delete all repeat event", nil];
    } else {
        deleteAlert = [[UIAlertView alloc]initWithTitle:@"Delete Event"
                                                message:nil
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"OK", nil];
    }
    [deleteAlert show];
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

    if (isAllDay) {
        isAllDay = NO;
        _alldayView.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
        _alldayView.layer.borderWidth = 1.0f;
        _allLabel.textColor = LightGrayColor;
        _dayLabel.textColor = LightGrayColor;
        _startDateLabel.font = [UIFont systemFontOfSize:13];
        _endDateLabel.font = [UIFont systemFontOfSize:13];
        _startTimeLabel.hidden = NO;
        _endTimeLabel.hidden = NO;
        _datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        _datePicker.minuteInterval = 5;

        _startDateFieldConstraint.constant = 0;
        _startDateConstraintTop.constant = 29;
        _endDateFieldConstraint.constant = 0;
        _endDateConstraintTop.constant = 29;
        
    } else {
        isAllDay = YES;
        _alldayView.backgroundColor = MainColor;
        _alldayView.layer.borderWidth = 0.0f;
        _allLabel.textColor = [UIColor whiteColor];
        _dayLabel.textColor = [UIColor whiteColor];
        _startDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        _endDateLabel.font = [UIFont fontWithName:@"Avenir-light" size:18];
        _startTimeLabel.hidden = YES;
        _endTimeLabel.hidden = YES;
        
        _startDateFieldConstraint.constant =14;
        _startDateConstraintTop.constant = 15;
        
        _endDateFieldConstraint.constant =14;
        _endDateConstraintTop.constant = 15;
        
        _datePicker.datePickerMode = UIDatePickerModeDate;
    }
    [_eventDetailView layoutIfNeeded];
}

-(void)changeDate
{
    if (!isAllDay) {
        if (_startTimeField.isFirstResponder) {
            _startDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            _startTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate: _datePicker.date]];
            eventStartDate = _datePicker.date;
            
            // Minimum end time after start time is selected
            minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_datePicker.date];
            eventEndDate = [NSDate dateWithTimeInterval:3600 sinceDate:_datePicker.date];
            _endDateLabel.text = [dateFormatter stringFromDate:eventEndDate];
            _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:eventEndDate]];
        }
        else {
            _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate: _datePicker.date]];
            _endDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            eventEndDate = _datePicker.date;
        }
    }
    else {
        if (_startTimeField.isFirstResponder) {
            _startDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            eventStartDate = _datePicker.date;

            minimumDate = _datePicker.date;
            _endDateLabel.text = [dateFormatter stringFromDate:minimumDate];
            eventEndDate = minimumDate;
        }
        else {
            _endDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
            eventEndDate = _datePicker.date;
        }
    }
}

#pragma mark - Reminder

- (void)removeAllAlarms
{
    if (_event.hasAlarms) {
        for (EKAlarm *a in _event.alarms) {
            [_event removeAlarm:a];
        }
    }
}

- (void)checkAlarm
{
    if (_event.hasAlarms) {
        for (EKAlarm *a in _event.alarms) {
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
            alarm = [EKAlarm alarmWithAbsoluteDate:_event.startDate];
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
    [_event addAlarm:alarm];
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
    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in _event.recurrenceRules) {
            [_event removeRecurrenceRule:r];
        }
    }
}

- (void)checkRule
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    int tag;
    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in _event.recurrenceRules) {
            EKRecurrenceFrequency frequency = r.frequency;
            NSInteger interval = r.interval;
            switch (frequency) {
                case EKRecurrenceFrequencyDaily:
                    tag = 2;
                    break;
                case EKRecurrenceFrequencyWeekly:
                    if (interval == 1)
                        tag = 3;
                    else
                        tag = 4;
                    break;
                case EKRecurrenceFrequencyMonthly:
                    tag = 5;
                    break;
                case EKRecurrenceFrequencyYearly:
                    tag = 6;
                    break;
                default:
                    break;
            }
        }
    }
    else {
        tag = 1;
    }
    
    for (UIButton *b in repeat.subviews) {
        if (b.tag == tag) {
            [b setSelected:YES];
            b.backgroundColor = MainColor;
            _repeatValueLabel.text = b.titleLabel.text;
            break;
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
        [_event addRecurrenceRule:recurrenceRule];
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
    
    _maskView.hidden = YES;
    _mapIcon.hidden = NO;
}

// Google search
-(void)queryGooglePlaces:(NSString *)name
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
