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
    CGRect startDateLabelFrame;
}
@property (weak, nonatomic) IBOutlet UILabel *eventTitle;
@property (weak, nonatomic) IBOutlet UILabel *eventDateTime;
@property (weak, nonatomic) IBOutlet UILabel *alldayLabel;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *calendarNameField;
@property (weak, nonatomic) IBOutlet UILabel *repeatLabel;
@property (weak, nonatomic) IBOutlet UIView *locationView;
@property (weak, nonatomic) IBOutlet UIView *repeatView;
@property (weak, nonatomic) IBOutlet UIView *calendarView;
@property (weak, nonatomic) IBOutlet UITextView *eventNotes;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;
@property (weak, nonatomic) IBOutlet UIView *notesView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *startArrorw;
@property (weak, nonatomic) IBOutlet UIImageView *endArrorw;
@property (weak, nonatomic) IBOutlet UIImageView *birthdayIcon;
@property (weak, nonatomic) IBOutlet UIImageView *facebookIcon;
@property (weak, nonatomic) IBOutlet UILabel *weekdayLabel;
@property (weak, nonatomic) IBOutlet UIView *timeView;

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
    
    if (_event.location)
        _locationLabel.text = _event.location;
    
    // Set up date formatter
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd , EEEE";
    
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
        _eventNotes.frame = CGRectOffset(_eventNotes.frame, 0, -40);
        _notesView.frame = CGRectOffset(_notesView.frame, 0, -40);

    }
    
    if (!_event.hasRecurrenceRules) {
        _repeatView.hidden = YES;
        _calendarView.frame = CGRectOffset(_calendarView.frame, 0, -40);
        _eventNotes.frame = CGRectOffset(_eventNotes.frame, 0, -40);
        _notesView.frame = CGRectOffset(_notesView.frame, 0, -40);
    }
    
    if (_event.hasNotes) {
        
        _eventNotes.hidden = NO;
        _notesView.hidden = NO;
        
        CGRect textViewRect = [_event.notes boundingRectWithSize:CGSizeMake(320, FLT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:[_eventNotes font]}
                                                         context:nil];
        
        CGRect textviewFrame = _eventNotes.frame;
        
        textviewFrame.size.height = textViewRect.size.height+20;
        [_eventNotes setFrame:textviewFrame];
        _eventNotes.text = _event.notes;
        
        if ((textViewRect.size.height + textviewFrame.origin.y) > [[UIScreen mainScreen]bounds].size.height) {
            CGSize contentSize =  _scrollview.frame.size;
            contentSize.height += ((textviewFrame.size.height  + textviewFrame.origin.y) - [[UIScreen mainScreen]bounds].size.height + 84);
            _scrollview.contentSize = contentSize;
        }
    } else {
        _eventNotes.hidden = YES;
        _notesView.hidden = YES;
    }
    
    startDateLabelFrame = _startDateLabel.frame;

}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    
    // Birthday icon
    if (_event.calendar.type == EKCalendarTypeBirthday)
        _birthdayIcon.hidden = NO;
    else
        _birthdayIcon.hidden = YES;
    
    // Facebook icon
    NSString *urlString = [NSString stringWithFormat:@"%@",_event.URL];
    if ([urlString rangeOfString:@"facebook"].location == NSNotFound)
        _facebookIcon.hidden  = YES;
    else
        _facebookIcon.hidden  = NO;

    // Time setup

    if (_event.allDay) {

        _timeView.frame = CGRectOffset(_timeView.frame, 0, -20);
        _locationView.frame = CGRectOffset(_locationView.frame, 0, -20);
        _repeatView.frame = CGRectOffset(_repeatView.frame, 0, -20);
        _calendarView.frame = CGRectOffset(_calendarView.frame, 0, -20);
        _eventNotes.frame = CGRectOffset(_eventNotes.frame, 0, -20);
        _notesView.frame = CGRectOffset(_notesView.frame, 0, -20);
        
        dateFormatter.dateFormat = @"yyyy/MM/dd";
        _startDateLabel.text = [dateFormatter stringFromDate:_event.startDate];
        
        dateFormatter.dateFormat = @"EEEE";
        _weekdayLabel.hidden = NO;
        _weekdayLabel.text = [dateFormatter stringFromDate:_event.startDate];

        _alldayLabel.hidden = NO;
        _startTimeLabel.hidden = YES;
        _endTimeLabel.hidden = YES;
        _startArrorw.hidden = YES;
        _endArrorw.hidden = YES;
        
        _alldayLabel.backgroundColor = MainColor;
        _alldayLabel.layer.borderWidth = 0.0f;
        _alldayLabel.textColor = [UIColor whiteColor];

        _startDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-light" size:17];
        _startDateLabel.frame = CGRectMake(50, 85, _startDateLabel.frame.size.width, _startDateLabel.frame.size.height);
        
        _startDateLabel.frame = CGRectOffset(_startDateLabel.frame, 0, -20);
        _weekdayLabel.frame = CGRectOffset(_weekdayLabel.frame, 0, -20);

        
    } else {
        dateFormatter.dateFormat = @"yyyy/MM/dd , EEEE";
        _startDateLabel.text = [dateFormatter stringFromDate:_event.startDate];
        _weekdayLabel.hidden = YES;

        _alldayLabel.hidden = YES;
        _startDateLabel.frame = startDateLabelFrame;
        _startDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-light" size:13];
        _startTimeLabel.hidden = NO;
        _endTimeLabel.hidden = NO;
        _startArrorw.hidden = NO;
        _endArrorw.hidden = NO;
        _startTimeLabel.attributedText =[self attributedTimeText:[timeFormatter stringFromDate:_event.startDate]];
        _endTimeLabel.attributedText = [self attributedTimeText:[timeFormatter stringFromDate:_event.endDate]];
    }
    

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
