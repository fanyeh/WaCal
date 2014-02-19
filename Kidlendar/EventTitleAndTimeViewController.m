//
//  EventTitleAndTimeViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventTitleAndTimeViewController.h"
#import "EventTitleAndTimeView.h"
#import "CalendarStore.h"

@interface EventTitleAndTimeViewController ()
{
    EventTitleAndTimeView *titleAndTimeView;
    CGRect titleViewFrameShow;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
    UIDatePicker *datePicker;
    NSDate *minimumDate;
    UIImageView *backgroundImageView;
}

@end

@implementation EventTitleAndTimeViewController

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
	// Do any additional setup after loading the view.
    // Do any additional setup after loading the view from its nib.
    backgroundImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    backgroundImageView.image = _backgroundImage;
    
    // Setup Date picker
    datePicker = [[UIDatePicker alloc]init];
    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [datePicker addTarget:self action:@selector(changeDate) forControlEvents:UIControlEventValueChanged];
    datePicker.minuteInterval = 5;
    datePicker.date = _selectedDate;
    
    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"MM月dd日 EEEE";
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    // Set up time and title view
    titleAndTimeView = [[EventTitleAndTimeView alloc]initWithFrame:CGRectMake(0, 0, 320, 352)];
    titleAndTimeView.titleField.delegate = self;
    [self.view addSubview:titleAndTimeView];
    titleAndTimeView.titleField.text = _event.title;
    [titleAndTimeView.titleField becomeFirstResponder];
    
    // Setup start time field , default setting is date/time when add button clicked
    titleAndTimeView.startTimeField.inputView = datePicker;
    titleAndTimeView.startTimeField.delegate = self;
    titleAndTimeView.startTimeField.dateLabel.text = [dateFormatter stringFromDate:_event.startDate];
    titleAndTimeView.startTimeField.text = [timeFormatter stringFromDate:_event.startDate];
    
    // Setup end time field , default setting is 5min from start time
    titleAndTimeView.endTimeField.inputView = datePicker;
    titleAndTimeView.endTimeField.delegate = self;
    titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate:_event.endDate];
    titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate:_event.endDate];
    
    [titleAndTimeView.allDayButton addTarget:self action:@selector(setEventToAllDay:) forControlEvents:UIControlEventTouchUpInside];
    
    // Put save button on navigation bar
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(saveEvent)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)setEventToAllDay:(UIButton *)sender
{
    if (sender.isSelected) {
        _event.allDay = NO;
        sender.backgroundColor = [UIColor yellowColor];
        sender.selected = NO;

    } else {
        _event.allDay = YES;
        sender.backgroundColor = [UIColor redColor];
        sender.selected = YES;
    }
}

- (void)saveEvent
{
    // Create new event
    _event.title = titleAndTimeView.titleField.text;
    [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
    NSDictionary *startDate = [NSDictionary dictionaryWithObject:_event.startDate forKey:@"startDate"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventChange" object:nil userInfo:startDate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(void)changeDate
{
    if (titleAndTimeView.startTimeField.isFirstResponder) {
        titleAndTimeView.startTimeField.dateLabel.text = [dateFormatter stringFromDate: datePicker.date];
        titleAndTimeView.startTimeField.text = [timeFormatter stringFromDate: datePicker.date];
        _event.startDate = datePicker.date;
        
        // Minimum end time after start time is selected
        minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:datePicker.date];
        titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate:minimumDate];
        titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate:minimumDate];
        _event.endDate = minimumDate;
    }
    else {
        titleAndTimeView.endTimeField.text = [timeFormatter stringFromDate: datePicker.date];
        titleAndTimeView.endTimeField.dateLabel.text = [dateFormatter stringFromDate: datePicker.date];
        _event.endDate = datePicker.date;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Tag 0 = title , 1 = startTime , 2 = endTime , 3 = locatoin
    switch (textField.tag) {
        case 1:
            datePicker.minimumDate = nil;
            [datePicker setDate:_event.startDate];
            textField.layer.borderColor = [[UIColor greenColor]CGColor];
            textField.layer.borderWidth = 1.0f;
            titleAndTimeView.endTimeField.layer.borderWidth = 0;
            break;
        case 2:
            datePicker.minimumDate = minimumDate;
            [datePicker setDate:_event.endDate];
            textField.layer.borderColor = [[UIColor redColor]CGColor];
            textField.layer.borderWidth = 1.0f;
            titleAndTimeView.startTimeField.layer.borderWidth = 0;
            break;
        default:
            break;
    }
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
