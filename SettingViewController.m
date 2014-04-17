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

@interface SettingViewController ()
{
    NSMutableDictionary *calendarDict;
    NSArray *calendarTitles;
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
    
    self.tableView.tintColor = MainColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingTableCell" bundle:nil] forCellReuseIdentifier:@"CalendarCell"];
    calendarDict = [[CalendarStore sharedStore]calendarDict];
    calendarTitles = [[calendarDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];;
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

#pragma mark - Table view data source

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
    headerLabel.text = calendarTitles[section];
    [headerView addSubview:headerLabel];
    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [calendarTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[calendarDict objectForKey:calendarTitles[section]]count];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CalendarCell";
    SettingTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SettingTableCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    // Configure the cell...
    NSMutableArray *selectedCalendars = [[CalendarStore sharedStore]selectedCalendars];
    NSMutableArray *calendarsByTitle = [calendarDict objectForKey:[calendarTitles objectAtIndex:indexPath.section]];
    EKCalendar *calendar = [calendarsByTitle objectAtIndex:indexPath.row];
    
    if ([selectedCalendars indexOfObject:calendar] != NSNotFound) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [cell setSelected:YES];
    }
    
    cell.calendarColorView.layer.cornerRadius = cell.calendarColorView.frame.size.width/2;
    cell.calendarNameLabel.text = calendar.title;
    cell.calendarColorView.backgroundColor = [UIColor colorWithCGColor:calendar.CGColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (calendar.type == EKCalendarTypeBirthday) {
        cell.birthdayIcon.hidden = NO;
        cell.calendarColorView.hidden = YES;
    } else {
        cell.birthdayIcon.hidden = YES;
        cell.calendarColorView.hidden = NO;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *calendarsByTitle = [calendarDict objectForKey:[calendarTitles objectAtIndex:indexPath.section]];
    EKCalendar *calendar = [calendarsByTitle objectAtIndex:indexPath.row];
    
    [[[CalendarStore sharedStore]selectedCalendars]addObject:calendar];
    [[[CalendarStore sharedStore]selectedCalIDs]addObject:calendar.calendarIdentifier];
    
    [[NSUserDefaults standardUserDefaults] setObject:[[CalendarStore sharedStore]selectedCalIDs] forKey:@"selectedCalendars"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil];
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *calendarsByTitle = [calendarDict objectForKey:[calendarTitles objectAtIndex:indexPath.section]];
    EKCalendar *calendar = [calendarsByTitle objectAtIndex:indexPath.row];
    
    [[[CalendarStore sharedStore]selectedCalendars]removeObject:calendar];
    [[[CalendarStore sharedStore]selectedCalIDs]removeObject:calendar.calendarIdentifier];

    [[NSUserDefaults standardUserDefaults] setObject:[[CalendarStore sharedStore]selectedCalIDs] forKey:@"selectedCalendars"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil];
}

@end
