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
{
    NSArray *social;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerClass:[SwitchCell class] forCellReuseIdentifier:@"SwitchCell"];
    social = @[@"Facebook",@"Dropbox"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section==0)
        return [[[CalendarStore sharedStore]allCalendars]count];
    else if (section==2)
        return [social count];
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
        if (calendar == [[CalendarStore sharedStore]calendar]){
            cell.detailTextLabel.text = @"This is current calendar";
        } else {
            cell.detailTextLabel.text = nil;
        }
        
        cell.textLabel.text = calendar.title;
        return cell;
    }
    else if (indexPath.section== 1) {
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
        static NSString *CellIdentifier = @"SwitchCell";
        SwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = [social objectAtIndex:indexPath.row];
        cell.cellSwitch.tag = indexPath.row;
        [cell.cellSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:[social objectAtIndex:indexPath.row]]];
        switch (indexPath.row) {
            case 0:
                [cell.cellSwitch addTarget:self action:@selector(facebookConnection:) forControlEvents:UIControlEventValueChanged];
                break;
            case 1:
                [cell.cellSwitch addTarget:self action:@selector(dropboxConnection:) forControlEvents:UIControlEventValueChanged];
                break;
            default:
                break;
        }
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

- (void)facebookConnection:(UISwitch *)sender
{
    [[FacebookModel shareModel] startFacebookSession];
}

- (void)dropboxConnection:(UISwitch *)sender
{
    NSString *key = [social objectAtIndex:sender.tag];

    if (sender.on) {
        NSLog(@"connection on");
        [[DBAccountManager sharedManager] linkFromController:self];
     } else {
        NSLog(@"connection off");
         [[[DBAccountManager sharedManager]linkedAccount]unlink];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:key];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *allCalendars = [[CalendarStore sharedStore]allCalendars];
    EKCalendar *calendar = allCalendars[indexPath.row];
    [CalendarStore sharedStore].calendar = calendar;
    [tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil];
}

@end
