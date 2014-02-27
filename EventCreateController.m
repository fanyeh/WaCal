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
#import "LocationDataStore.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
#define kGOOGLE_API_KEY @"AIzaSyAD9e182Fr19_2DcJFZYUHf6wEeXjxs_kQ"


@interface EventCreateController () <UITextFieldDelegate,UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate>
{
    EKEvent *event;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    NSDate *minimumDate;
    ReminderView *reminder;
    RepeatView *repeat;
    EKAlarm *alarm;
    EKRecurrenceRule *recurrenceRule;
    CGRect hideFrame;
    NSArray *places;
    double locationLat;
    double locationLng;
}
@property (weak, nonatomic) IBOutlet UITextField *subjectField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *startTimeField;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *endTimeField;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UIView *reminderView;
@property (weak, nonatomic) IBOutlet UIView *repeatView;
@property (weak, nonatomic) IBOutlet UIButton *allDayBtn;
@property (weak, nonatomic) IBOutlet UIView *eventDetailView;
@property (weak, nonatomic) IBOutlet UISearchBar *locationSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchResultTable;
@property (weak, nonatomic) IBOutlet UIView *locationSearchView;
@property (weak, nonatomic) IBOutlet UIView *maskView;

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
    
    // Navgition save button
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveNewEvent)];
    self.navigationItem.title = @"New Event";
    
    _locationSearchBar.delegate = self;
    
    _searchResultTable.delegate = self;
    _searchResultTable.dataSource = self;
    [_searchResultTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    _locationSearchView.layer.cornerRadius = 10.0f;

    // Event detail view
    _eventDetailView.layer.cornerRadius = 5.0f;
    
    // Reminder view
    _reminderView.layer.cornerRadius = 5.0f;
    UITapGestureRecognizer *reminderTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showReminder)];
    [_reminderView addGestureRecognizer:reminderTap];
    
    // Reminder selection view
    reminder = [[ReminderView alloc]init];
    for (UIButton *b in reminder.subviews) {
        [b addTarget:self action:@selector(alarmTap:) forControlEvents:UIControlEventTouchDown];
    }
    [self checkAlarm];
    [self.view addSubview:reminder];
    
    // Repeat view
    _repeatView.layer.cornerRadius = 5.0f;
    UITapGestureRecognizer *repeatTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showRepeat)];
    [_repeatView addGestureRecognizer:repeatTap];
    
    // Repeat selection view
    repeat = [[RepeatView alloc]init];
    for (UIButton *b in repeat.subviews) {
        [b addTarget:self action:@selector(recurrenceBtn:) forControlEvents:UIControlEventTouchDown];
    }
    [self checkRule];
    [self.view addSubview:repeat];

    hideFrame = reminder.frame;

    // Set up All Day button
    [_allDayBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Set up time formatter
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Setup Date picker
    _datePicker = [[UIDatePicker alloc]init];
    [_datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [_datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    _datePicker.minuteInterval = 5;
    _datePicker.date = _selectedDate;
    
    // When enter bring up title and time view and keyboard
    _subjectField.delegate = self;
    [_subjectField becomeFirstResponder];
    _locationField.delegate = self;
    _locationField.rightViewMode = UITextFieldViewModeWhileEditing;
    UIView *locationRightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    UITapGestureRecognizer *rightViewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(searchLocation)];
    [locationRightView addGestureRecognizer:rightViewTap];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(5, 5, 20, 20)];
    imageView.image = [UIImage imageNamed:@"searchicon.png"];
    [locationRightView addSubview:imageView];
    _locationField.rightView = locationRightView;
    
    _startTimeField.delegate = self;
    _startTimeField.inputView = _datePicker;
    _endTimeField.delegate = self;
    _endTimeField.inputView = _datePicker;
    
    _startTimeField.text = [timeFormatter stringFromDate:_selectedDate];
    _startDateLabel.text = [dateFormatter stringFromDate:_selectedDate];
    
    _endTimeField.text = [timeFormatter stringFromDate:[NSDate dateWithTimeInterval:300 sinceDate:_selectedDate]];
    _endDateLabel.text =  [dateFormatter stringFromDate:[NSDate dateWithTimeInterval:300 sinceDate:_selectedDate]];
    
    // Initialize new event
    event = [EKEvent eventWithEventStore:[[CalendarStore sharedStore]eventStore]];
    event.timeZone = [NSTimeZone systemTimeZone];
    event.calendar = [[CalendarStore sharedStore]calendar];
    event.startDate = _selectedDate;
    event.endDate = [NSDate dateWithTimeInterval:300 sinceDate:_selectedDate];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
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

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Tag 0 = title , 1 = startTime , 2 = endTime , 3 = locatoin
    switch (textField.tag) {
        case 1:
            if ([_subjectField isFirstResponder])
                _datePicker.minimumDate = nil;
            [_datePicker setDate:event.startDate];
            break;
        case 2:
            _datePicker.minimumDate = minimumDate;
            [_datePicker setDate:event.endDate];
            break;
        default:
            break;
    }
    
    repeat.frame = hideFrame;
    repeat.show = NO;
    reminder.frame = hideFrame;
    reminder.show = NO;
    return YES;
}

#pragma mark - User actions
- (void)saveNewEvent
{
    if (locationLng > 0 && locationLat > 0) {
        LocationData *locationData = [[LocationDataStore sharedStore]createItemWithKey:event.eventIdentifier];
        locationData.latitude = locationLat;
        locationData.longitude = locationLng;
        [[LocationDataStore sharedStore]saveChanges];
    }
    
    // Create new event
    event.title = _subjectField.text;
    event.location = _locationField.text;
    [[[CalendarStore sharedStore]eventStore] saveEvent:event span:EKSpanThisEvent commit:YES error:nil];
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
}

- (void)searchLocation
{
    _locationSearchBar.text = _locationField.text;
    [self queryGooglePlacesLongitude:_locationField.text];
    _maskView.hidden = NO;
}

-(void)showReminder
{
    if (!reminder.show) {
        [self.view endEditing:YES];
        repeat.frame = hideFrame;
        repeat.show = NO;
        reminder.frame = CGRectOffset(reminder.frame, 0, -216);
        reminder.show = YES;
    }
}

-(void)showRepeat
{
    if (!repeat.show) {
        [self.view endEditing:YES];
        reminder.frame = hideFrame;
        reminder.show = NO;
        repeat.frame = CGRectOffset(repeat.frame, 0, -216);
        repeat.show = YES;
    }
}

- (IBAction)alldayBtn:(UIButton *)sender
{
    if (sender.isSelected) {
        event.allDay = NO;
        sender.backgroundColor = [UIColor whiteColor];
        sender.selected = NO;
    } else {
        event.allDay = YES;
        sender.backgroundColor = Rgb2UIColor(33, 138, 251);
        sender.selected = YES;
    }
}

-(void)changeDate
{
    if (_startTimeField.isFirstResponder) {
        _startDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
        _startTimeField.text = [timeFormatter stringFromDate: _datePicker.date];
        event.startDate = _datePicker.date;
        
        // Minimum end time after start time is selected
        minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:_datePicker.date];
        _endDateLabel.text = [dateFormatter stringFromDate:minimumDate];
        _endTimeField.text = [timeFormatter stringFromDate:minimumDate];
        event.endDate = minimumDate;
    }
    else {
        _endTimeField.text = [timeFormatter stringFromDate: _datePicker.date];
        _endDateLabel.text = [dateFormatter stringFromDate: _datePicker.date];
        event.endDate = _datePicker.date;
    }
}

- (void)createEvent
{
    event.title = _subjectField.text;
    NSError *err;
    if ([[[CalendarStore sharedStore]eventStore] saveEvent:event span:EKSpanThisEvent commit:YES error:&err])
        NSLog(@"New event created");
    else
        NSLog(@"Create new event fail");
    NSLog(@"Error From calendar : %@", [err description]);
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Reminder

- (void)removeAllAlarms
{
    if (event.hasAlarms) {
        for (EKAlarm *a in event.alarms) {
            [event removeAlarm:a];
        }
    }
}

- (void)checkAlarm
{
    if (event.hasAlarms) {
        for (EKAlarm *a in event.alarms) {
            NSLog(@"alarm %@",a);
            for (ReminderButton *b in reminder.subviews) {
                if ((b.tag==1&&a.absoluteDate)||(b.timeOffset == a.relativeOffset*-1)) {
                    [b setSelected:YES];
                    b.backgroundColor = Rgb2UIColor(33, 138, 251);
                    break;
                }
            }
        }
    }
}

- (void)alarmTap:(UIButton *)sender
{
    // Tag : 1 - on time , 2 - 5min , 3 - 15min , 4 - 30min , 5 - 1hour , 6 - 2hour ,7 - 1day , 8 - 2Day , 9 - 1week
    if([sender isSelected]){
        [sender setSelected:NO];
        if (sender.tag < 10)
            sender.backgroundColor = [UIColor whiteColor];
    } else {
        [sender setSelected:YES];
        if (sender.tag < 10) {
            sender.backgroundColor = Rgb2UIColor(33, 138, 251);
            [self createAlarm:sender.tag];
        }
        
        // Change all other buttons to unselect
        for (ReminderButton *b in reminder.subviews) {
            if (b.tag < 10 && b.tag != sender.tag) {
                [b setSelected:NO];
                b.backgroundColor = [UIColor whiteColor];
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

#pragma mark - Repeat

- (void)recurrenceBtn:(UIButton *)sender
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    if([sender isSelected]){
        [sender setSelected:NO];
        if (sender.tag < 10)
            sender.backgroundColor = [UIColor whiteColor];
        
    } else {
        [sender setSelected:YES];
        if (sender.tag < 10) {
            sender.backgroundColor = Rgb2UIColor(33, 138, 251);
            [self createRule:sender.tag];
        }
        
        // Change all other buttons to unselect
        for (UIButton *b in repeat.subviews) {
            if (b.tag < 10 && b.tag != sender.tag) {
                [b setSelected:NO];
                b.backgroundColor = [UIColor whiteColor];
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

- (void)checkRule
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    int tag;
    if (event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in event.recurrenceRules) {
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
    
    for (UIButton *b in self.view.subviews) {
        if (b.tag == tag) {
            [b setSelected:YES];
            b.layer.borderColor = [[UIColor greenColor]CGColor];
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
    [event addRecurrenceRule:recurrenceRule];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _locationField.text = searchBar.text;
    [self queryGooglePlacesLongitude:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _maskView.hidden = YES;
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
    locationLat =  [[[[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
    locationLng =  [[[[places[indexPath.row] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
    _maskView.hidden = YES;
}

// Google search
-(void) queryGooglePlacesLongitude:(NSString *)name
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
                                   //                                   NSLog(@"Places %@",places);
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



@end
