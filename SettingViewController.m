//
//  SettingViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/6.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "SettingViewController.h"
#import "CalendarStore.h"
#import <EventKit/EventKit.h>
#import "SwitchCell.h"
#import "SettingTableCell.h"

@interface SettingViewController () <UIPickerViewDataSource,UIPickerViewDelegate>
{
    UIPickerView *alarmPicker;
    NSArray *alarm;
    UITextField *fakeAlarmField;
}

@end

@implementation SettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0],NSFontAttributeName,
                          [UIColor whiteColor],NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationItem.title = @"Setting";
    
//    [self.tableView registerClass:[SwitchCell class] forCellReuseIdentifier:@"SwitchCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingTableCell" bundle:nil] forCellReuseIdentifier:@"CalendarCell"];
    
    alarmPicker = [[UIPickerView alloc]init];
    alarmPicker.delegate = self;
    alarmPicker.dataSource = self;
    
    alarm = @[@"On Time",@"5 Min",@"15 Min",@"30 Min",@"1 Hour",@"2 Hours",@"1 Day",@"2 Days",@"1 Week"];
    
    fakeAlarmField = [[UITextField alloc]init];
    fakeAlarmField.inputView = alarmPicker;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [alarm count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return alarm[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSInteger timer;
    switch (row+1) {
        case 1:
            timer=0;
            break;
        case 2:
            timer=-60*5;
            break;
        case 3:
            timer=-60*15;
            break;
        case 4:
            timer=-60*30;
            break;
        case 5:
            timer=-60*60;
            break;
        case 6:
            timer=-60*120;
            break;
        case 7:
            timer=-60*60*24;
            break;
        case 8:
            timer=-60*60*24*2;
            break;
        case 9:
            timer=-60*60*24*7;
            break;
        default:
            timer=0;
            break;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:timer forKey:@"defaultAlarm"];
    [self.tableView reloadData];
    [fakeAlarmField resignFirstResponder];
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


#pragma mark - Table view data source
#define MainColor [UIColor colorWithRed:(64 / 255.0) green:(98 / 255.0) blue:(124 / 255.0) alpha:1.0]

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
    headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.000];
    headerView.layer.shadowOpacity = 0.3f;
    headerView.layer.shadowColor = [[UIColor colorWithWhite:0.502 alpha:1.000]CGColor];
    headerView.layer.shadowOffset = CGSizeMake(0, 1);
    
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(30, 0, 300, 30)];
    headerLabel.textColor = MainColor;
    headerLabel.textAlignment = NSTextAlignmentLeft;
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
    headerLabel.center = headerView.center;
    headerLabel.text = @"Calendar";
    [headerView addSubview:headerLabel];
    return headerView;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section==0)
        return [[[CalendarStore sharedStore]allCalendars]count];
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Calendar
    if (indexPath.section == 0) {

        static NSString *CellIdentifier = @"CalendarCell";
        SettingTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SettingTableCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
    
        // Configure the cell...
        NSArray *allCalendars = [[CalendarStore sharedStore]allCalendars];
        EKCalendar *calendar = allCalendars[indexPath.row];
        if (calendar == [[CalendarStore sharedStore]calendar]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
        cell.calendarColorView.layer.cornerRadius = cell.calendarColorView.frame.size.width/2;
        cell.calendarColorView.backgroundColor = [UIColor colorWithCGColor:calendar.CGColor];
        cell.calendarNameLabel.text = calendar.title;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    // Face Detection
    else  if (indexPath.section == 1){
        static NSString *CellIdentifier = @"SwitchCell";
        SwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

        cell.textLabel.text =@"Face Detection";
        [cell.cellSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"FaceDetection"]];
        [cell.cellSwitch addTarget:self action:@selector(disableFaceDetection:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    
    // Default Alarm
    else {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text =@"Calendar Reminder";
        cell.detailTextLabel.text =[self minuteToString:[[NSUserDefaults standardUserDefaults] integerForKey:@"defaultAlarm"]];
        [cell.contentView addSubview:fakeAlarmField];
        
        return cell;
    }
}


- (void)disableFaceDetection:(UISwitch *)sender
{
    if (sender.on) {
        NSLog(@"Switch on");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FaceDetection"];
    } else {
        NSLog(@"Switch off");
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FaceDetection"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSArray *allCalendars = [[CalendarStore sharedStore]allCalendars];
        EKCalendar *calendar = allCalendars[indexPath.row];
        [CalendarStore sharedStore].calendar = calendar;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil];
    } else if (indexPath.section == 2) {
        [fakeAlarmField becomeFirstResponder];
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (indexPath.section == 2) {
        [fakeAlarmField resignFirstResponder];
    }
}

@end
