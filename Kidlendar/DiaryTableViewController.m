//
//  DiaryTableViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryTableViewController.h"
#import "DiaryDataStore.h"
#import "DiaryData.h"
#import "DiaryViewController.h"
#import "DiaryCreateViewController.h"
#import "DiaryTableViewCell.h"
#import "LocationData.h"
#import "LocationDataStore.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@interface DiaryTableViewController ()
{
    NSMutableDictionary *cloudDiarys;
    BOOL currentTableIsLocal;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *weekdayFormatter;
    NSArray *monthArray;
    NSMutableDictionary *diaryInSections;
}
@end

@implementation DiaryTableViewController

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
//    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = Rgb2UIColor(236, 240, 241);
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(createDiary)];
    self.navigationItem.rightBarButtonItem = addButton;

    // Date formatters
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"dd";
    weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
    
    // Set up table
    [self.tableView registerNib:[UINib nibWithNibName:@"DiaryTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"DiaryTableViewCell"];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];
//    diaryInSections = [[NSMutableDictionary alloc]init];
    [self sortDiaryToSection];
    
    // Add observer to monitor event when new calendar event is created or removed
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshDiary:)
                                                name:@"diaryChange" object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [[self.tabBarController.tabBar.items objectAtIndex:1]setBadgeValue:nil];
    [self.tableView endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshDiary:(NSNotification *)notification
{
    [self sortDiaryToSection];
    [self.tableView reloadData];
}

- (void)sortDiaryToSection
{
    NSArray *diaryArray = [[DiaryDataStore sharedStore]allItems];
    diaryInSections = [[NSMutableDictionary alloc]init];

    for (DiaryData *d in diaryArray) {
        NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
        NSDateComponents *comp = [[NSCalendar currentCalendar]components:(NSCalendarUnitYear|NSCalendarUnitMonth) fromDate:diaryDate];
        NSString *sectionKey = [NSString stringWithFormat:@"%ld-%@",(long)[comp year],monthArray[[comp month]]];
        if (![diaryInSections objectForKey:sectionKey]) {
            NSMutableArray *diarySet = [[NSMutableArray alloc]init];
            [diarySet addObject:d];
            [diaryInSections setObject:diarySet forKey:sectionKey];
        }
        else {
            NSMutableArray *diarySet = [diaryInSections objectForKey:sectionKey];
            [diarySet addObject:d];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [diaryInSections.allKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSString *sectionKey =diaryInSections.allKeys[section];
    return [[diaryInSections objectForKey:sectionKey] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryTableViewCell *cell = (DiaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryTableViewCell"];
    if (!cell)
        cell =[[DiaryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiaryTableViewCell"];
    cell.cellImageView.layer.cornerRadius = 5.0f;
    cell.cellImageView.layer.masksToBounds = YES;
//    cell.cellView.layer.shadowColor = [[UIColor blackColor]CGColor];
//    cell.cellView.layer.shadowOpacity = 0.5f;
//    cell.cellView.layer.shadowOffset = CGSizeMake(2 , 2);

    // Configure the cell...
//    DiaryData *d = [DiaryDataStore sharedStore].allItems[indexPath.row];
    NSString *sectionKey =diaryInSections.allKeys[indexPath.section];
    DiaryData *d = [[diaryInSections objectForKey:sectionKey] objectAtIndex:indexPath.row];
    
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
    cell.dateLabel.text = [dateFormatter stringFromDate:diaryDate];
    cell.weekdayLabel.adjustsFontSizeToFitWidth = YES;
    cell.weekdayLabel.text = [weekdayFormatter stringFromDate:diaryDate];
    cell.locationLabel.text = d.location;
    cell.diaryDetail.text = d.diaryText;
    cell.diarySubject.text = d.subject;
    
    if (d.diaryVideoPath) {
        cell.cellImageView.image = d.diaryVideoThumbnail;
        cell.videoPlayButton.hidden = NO;
    } else {
        cell.cellImageView.image = d.diaryImage;
        cell.videoPlayButton.hidden = YES;
    }
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSString *sectionKey =diaryInSections.allKeys[indexPath.section];
        DiaryData *d = [[diaryInSections objectForKey:sectionKey] objectAtIndex:indexPath.row];
        [[DiaryDataStore sharedStore] removeItem:d];
        
        // Delete item from sort diary and row
        if ([[[DiaryDataStore sharedStore]allItems]count] > 0) {
            [[diaryInSections objectForKey:sectionKey] removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
        }
        else {
            [diaryInSections removeObjectForKey:sectionKey];
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryChange" object:nil];
    }
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryViewController *controller = [[DiaryViewController alloc]init];
    NSString *sectionKey =diaryInSections.allKeys[indexPath.section];
    controller.diaryData = [[diaryInSections objectForKey:sectionKey] objectAtIndex:indexPath.row];

    [self.navigationController pushViewController:controller animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 101; // 可在 XIB 檔案，點選 My Talbe View Cell 從 Size inspector 得知
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerView.backgroundColor = [UIColor redColor];
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerLabel.textColor = Rgb2UIColor(33, 138, 251);
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = [UIFont fontWithName:@"Avenir" size:20];
    headerLabel.center = headerView.center;
    headerLabel.text = [diaryInSections.allKeys objectAtIndex:section];
    [headerView addSubview:headerLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (void)createDiary
{
    DiaryCreateViewController *createViewController = [[DiaryCreateViewController alloc]init];
    [self.navigationController pushViewController:createViewController animated:YES];
}

-(void)editDiaryTable
{
    if (self.navigationItem.leftBarButtonItem.tag == 0) {
        [self setEditing:YES animated:YES];
        self.navigationItem.leftBarButtonItem.tag = 1;
    }
    else
    {
        [self setEditing:NO animated:YES];
        self.navigationItem.leftBarButtonItem.tag = 0;
    }
}

@end
