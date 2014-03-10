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
#import <Dropbox/Dropbox.h>
#import "FacebookModel.h"

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
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationItem.title = @"Setting";
    
    [self.tableView registerClass:[SwitchCell class] forCellReuseIdentifier:@"SwitchCell"];
    
    alarmPicker = [[UIPickerView alloc]init];
    alarmPicker.delegate = self;
    alarmPicker.dataSource = self;
    
    alarm = @[@"On Time",@"5 Min",@"15 Min",@"30 Min",@"1 Hour",@"2 Hour",@"1 Day",@"2 Day",@"7 Day"];
    
    fakeAlarmField = [[UITextField alloc]init];
    fakeAlarmField.inputView = alarmPicker;
}

- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:YES];
//    [self.tableView reloadData];
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
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
    if (indexPath.section == 0) {

        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
    
        // Configure the cell...
        NSArray *allCalendars = [[CalendarStore sharedStore]allCalendars];
        EKCalendar *calendar = allCalendars[indexPath.row];
        if (cell.isSelected)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        cell.textLabel.text = calendar.title;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
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
    
    else {
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text =@"Calendar Reminder";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld Min", [[NSUserDefaults standardUserDefaults] integerForKey:@"defaultAlarm"]/-60];
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
