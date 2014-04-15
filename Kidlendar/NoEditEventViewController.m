//
//  NoEditEventViewController.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/14.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "NoEditEventViewController.h"
#import "ReminderView.h"
#import "ReminderButton.h"

@interface NoEditEventViewController ()  <UITextFieldDelegate>
{
    NSDateFormatter *dateFormatter;
    NSDateFormatter *timeFormatter;
}
@property (weak, nonatomic) IBOutlet UILabel *eventTitle;
@property (weak, nonatomic) IBOutlet UILabel *eventWeekday;
@property (weak, nonatomic) IBOutlet UILabel *calendarName;
@property (weak, nonatomic) IBOutlet UILabel *eventDateTime;
@property (weak, nonatomic) IBOutlet UILabel *alldayLabel;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *calendarNameField;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UIView *locationView;
@property (weak, nonatomic) IBOutlet UIView *repeatView;
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UIView *attendeeView;
@property (weak, nonatomic) IBOutlet UITextView *eventNotes;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;

@end

@implementation NoEditEventViewController

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
    self.navigationItem.title = @"Event Details";
    self.automaticallyAdjustsScrollViewInsets = NO;

    _eventTitle.text = _event.title;
    _calendarName.text = _event.calendar.title;    
    NSDateComponents *comp = [[NSCalendar currentCalendar]components:NSWeekdayCalendarUnit fromDate:_event.startDate];
    
    _eventWeekday.text = [self convertWeekday:[comp weekday]];
    
    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    
    // Set up time formatter
    timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat =  @"hh:mm aa";
    
    NSMutableString *recurrenceString = [[NSMutableString alloc]init];

    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *e in _event.recurrenceRules) {
        
            if (e.interval == 1)
                [recurrenceString appendString:[NSString stringWithFormat:@"Every %@",[self getFrequency:e.frequency]]];
            else
                [recurrenceString appendString:[NSString stringWithFormat:@"Every %ld %@",e.interval,[self getFrequency:e.frequency]]];
        }
    }
    
    _repeatLabel.text = recurrenceString;
    
    UIView *leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
    
    UIView *dotView = [[UIView alloc]initWithFrame:CGRectMake(12, 12, 6, 6)];
    dotView.layer.cornerRadius = dotView.frame.size.width/2;
    dotView.backgroundColor = [UIColor colorWithCGColor:_event.calendar.CGColor];
    [leftView addSubview:dotView];
    
    UIFont* currentFont = [_calendarNameField font];
    CGSize newSize = [_event.calendar.title sizeWithAttributes:@{NSFontAttributeName:currentFont}];
    CGRect finalFrame = _calendarNameField.frame;
    finalFrame.origin.x = 320 - 10 - newSize.width - 30;
    finalFrame.size.width = newSize.width + 30;
    [_calendarNameField setFrame:finalFrame];
    _calendarNameField.leftView = leftView;
    _calendarNameField.leftViewMode = UITextFieldViewModeAlways;
    _calendarNameField.text = _event.calendar.title;
    
    if (!_event.location) {
        _locationView.hidden = YES;
        _repeatView.frame = CGRectOffset(_repeatView.frame, 0, -40);
        _calendarView.frame = CGRectOffset(_calendarView.frame, 0, -40);
        _attendeeView.frame = CGRectOffset(_attendeeView.frame, 0, -40);
    }
    
    if (!_event.hasRecurrenceRules) {
        _repeatView.hidden = YES;
        _calendarView.frame = CGRectOffset(_calendarView.frame, 0, -40);
        _attendeeView.frame = CGRectOffset(_attendeeView.frame, 0, -40);
    }
    
    CGSize textviewSize = [_event.notes sizeWithAttributes:@{NSFontAttributeName:[_eventNotes font]}];
    NSLog(@"textviewSize size %@",[NSValue valueWithCGSize:textviewSize]);

    CGRect textviewFrame = _eventNotes.frame;
    CGFloat originalHeigh = textviewFrame.size.height;
    textviewFrame.size.height = textviewSize.width;
    [_eventNotes setFrame:textviewFrame];
    _eventNotes.text = _event.notes;
    
    if ((textviewSize.height + textviewFrame.origin.y) > [[UIScreen mainScreen]bounds].size.height) {
        CGSize contentSize =  _scrollview.frame.size;
        NSLog(@"content size %@",[NSValue valueWithCGSize:contentSize]);

        contentSize.height += ((textviewSize.width + textviewFrame.origin.y) - [[UIScreen mainScreen]bounds].size.height);
        _scrollview.contentSize = contentSize;
        NSLog(@"content size %@",[NSValue valueWithCGSize:contentSize]);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    _endDateLabel.text =  [dateFormatter stringFromDate:_event.endDate];
    _startDateLabel.text = [dateFormatter stringFromDate:_event.startDate];
    
    if (_event.allDay) {
        _alldayLabel.backgroundColor = MainColor;
        _alldayLabel.layer.borderWidth = 0.0f;
        _alldayLabel.textColor = [UIColor whiteColor];
        
        _startDateLabel.frame = CGRectOffset(_startDateLabel.frame, 0 , -13);
        _eventWeekday.frame = CGRectOffset(_eventWeekday.frame, 0 , -13);
        _startDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-light" size:17];
        _endDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-light" size:17];
        
        _startTimeLabel.hidden = YES;
        _endTimeLabel.hidden = YES;
        _endDateLabel.hidden = YES;
        _eventWeekday.hidden = NO;
        
        _startTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_event.startDate]];
        _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_event.endDate]];

 
    } else {
        _alldayLabel.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
        _alldayLabel.layer.borderWidth = 1.0f;
        _alldayLabel.layer.borderColor = LightGrayColor.CGColor;
        _alldayLabel.textColor = LightGrayColor;
        
//        _startDateLabel.frame = CGRectOffset(_startDateLabel.frame, 0, 13);
//        _endDateLabel.frame = CGRectOffset(_endDateLabel.frame, 0 , 13);
//        _startDateLabel.font = [UIFont systemFontOfSize:13];
//        _endDateLabel.font = [UIFont systemFontOfSize:13];
        
        _startTimeLabel.hidden = NO;
        _endTimeLabel.hidden = NO;
        _eventWeekday.hidden = YES;
        
        _startTimeLabel.attributedText =[self attributedTimeText:[timeFormatter stringFromDate:_event.startDate]];
        _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_event.endDate]];
    }
    
    self.tabBarController.tabBar.hidden = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (NSString *)convertWeekday:(NSInteger)weekday
{
    switch (weekday) {
        case 1:
            return @"Sunday";
            break;
        case 2:
            return @"Monday";
            break;
        case 3:
            return @"Tuesday";
            break;
        case 4:
            return @"Wednesday";
            break;
        case 5:
            return @"Thursday";
            break;
        case 6:
            return @"Friday";
            break;
        case 7:
            return @"Saturday";
            break;
        default:
            return nil;
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

-(NSString *)getFrequency:(EKRecurrenceFrequency)frequency
{
    NSString *freq;
    switch (frequency) {
        case EKRecurrenceFrequencyDaily:
            freq = @"Day";
            break;
        case EKRecurrenceFrequencyWeekly:
            freq = @"Week";
            break;
        case EKRecurrenceFrequencyMonthly:
            freq = @"Month";
            break;
        case EKRecurrenceFrequencyYearly:
            freq = @"Year";
            break;
        default:
            break;
    }
    return freq;
}

@end
