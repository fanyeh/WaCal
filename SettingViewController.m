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

@interface SettingViewController ()

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
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
    else  {
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
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
