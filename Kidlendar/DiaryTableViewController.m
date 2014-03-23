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
#import "DiaryCreateViewController.h"
#import "DiaryTableViewCell.h"
#import "LocationData.h"
#import "LocationDataStore.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "DiaryPageViewController.h"
#import "UIImage+Resize.h"
#import "FileManager.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
#define MainColor [UIColor colorWithRed:(64 / 255.0) green:(98 / 255.0) blue:(124 / 255.0) alpha:1.0]

@interface DiaryTableViewController ()
{
    NSMutableDictionary *cloudDiarys;
    BOOL currentTableIsLocal;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *weekdayFormatter;
    NSArray *monthArray;
    NSArray *weekdayArray;
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
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(createDiary)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.navigationItem.title = @"Moments";

    // Date formatters
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
    
    // Set up table
    [self.tableView registerNib:[UINib nibWithNibName:@"DiaryTableViewCell" bundle:nil] forCellReuseIdentifier:@"DiaryTableViewCell"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];
    weekdayArray = @[@"Sunday",@"Monday",@"Tuesday",@"Wedneday",@"Thursday",@"Friday",@"Saturday"];
    [self sortDiaryToSection];
    
    // Add observer to monitor event when new calendar event is created or removed
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshDiary:)
                                                name:@"diaryChange" object:nil];
    
    self.tableView.showsVerticalScrollIndicator = NO;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showUploadProgress:) name:@"uploadVideo" object:nil];


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
    diaryInSections = [[NSMutableDictionary alloc]init];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    NSArray *sortedArray = [[[DiaryDataStore sharedStore]allItems] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    for (DiaryData *d in sortedArray) {
        NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
        NSDateComponents *comp = [[NSCalendar currentCalendar]components:(NSCalendarUnitYear|NSCalendarUnitMonth) fromDate:diaryDate];
        NSString *sectionKey = [NSString stringWithFormat:@"%@ %ld",monthArray[[comp month]-1],(long)[comp year]];
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

-(void)showUploadProgress:(NSNotification *)notification
{
    NSLog(@"Table view progress");
    NSString *diaryKey = [[notification userInfo]objectForKey:@"diaryKey"];
    
    NSArray *sectionKeys = diaryInSections.allKeys;
    for (NSString *k in sectionKeys) {
        NSMutableArray *m = [diaryInSections objectForKey:k];
        for (DiaryData *d in m) {
            if ([d.diaryKey isEqualToString:diaryKey]) {
                NSInteger section = [sectionKeys indexOfObject:k];
                NSInteger index = [m indexOfObject:d];
                NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:section];
                DiaryTableViewCell *cell = (DiaryTableViewCell *)[self.tableView cellForRowAtIndexPath:path];
                cell.circleProgressView.hidden = NO;
                float progress = [[notification object] floatValue];
                [cell.circleProgressView updateProgress:progress];
                cell.progressLabel.text = [NSString stringWithFormat:@"%0.f%%",progress*100];
                [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
            }
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
    DiaryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiaryTableViewCell"];
    if (!cell)
        cell =[[DiaryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiaryTableViewCell"];
    NSString *sectionKey =diaryInSections.allKeys[indexPath.section];
    DiaryData *d = [[diaryInSections objectForKey:sectionKey] objectAtIndex:indexPath.row];
    
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
    NSDateComponents *comp = [[NSCalendar currentCalendar]components:(NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:diaryDate];
    
    NSInteger day = [comp day];
    NSString *dayString;
    switch (day%10) {
        case 1:
            if (day==11)
                dayString = @"th";
            else
                dayString = @"st";
            break;
        case 2:
            dayString = @"nd";
            break;
        case 3:
            dayString = @"rd";
            break;
        default:
            dayString = @"th";
            break;
    }
    NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld%@ %@",(long)day,dayString,[weekdayFormatter stringFromDate:diaryDate]]];
    NSRange selectedRange = NSMakeRange(2, 2); // 4 characters, starting at index 22
    
    [dateString beginEditing];
    
    [dateString addAttribute:NSFontAttributeName
                   value:[UIFont fontWithName:@"HelveticaNeue-Light" size:11.0]
                   range:selectedRange];
    
    [dateString endEditing];
    cell.dateLabel.attributedText = dateString;
    
    if (d.location.length > 0) {
        cell.locationTag.hidden = NO;
        cell.locationLabel.text = d.location;
    } else {
        cell.locationTag.hidden = YES;
        cell.locationLabel.text = nil;
    }
    cell.diaryDetail.text = d.diaryText;
    cell.diarySubject.text = d.subject;
    
    if (d.diaryVideoPath) {
        cell.cellImageView.image = d.diaryVideoThumbnail;
        cell.videoPlayView.layer.borderWidth = 2.0f;
        cell.videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
        cell.videoPlayView.layer.cornerRadius = cell.videoPlayView.frame.size.width/2;
        cell.videoPlayView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        cell.videoPlayView.hidden = NO;
    } else {
        cell.cellImageView.image = [d.diaryPhotoThumbnail resizeImageToSize:cell.cellImageView.frame.size];
        cell.videoPlayView.hidden = YES;
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
        FileManager *fm = [[FileManager alloc]initWithKey:d.diaryKey];
        [fm removeCollectionImage];
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
    DiaryPageViewController *controller = [[DiaryPageViewController alloc]init];
    NSString *sectionKey =diaryInSections.allKeys[indexPath.section];
    controller.diaryData = [[diaryInSections objectForKey:sectionKey] objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80; // 可在 XIB 檔案，點選 My Talbe View Cell 從 Size inspector 得知
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
    headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.000];
    headerView.layer.shadowOpacity = 0.3f;
    headerView.layer.shadowColor = [[UIColor colorWithWhite:0.502 alpha:1.000]CGColor];
    headerView.layer.shadowOffset = CGSizeMake(0, 1);
    
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 320, 30)];
    headerLabel.textColor = MainColor;
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
    headerLabel.center = headerView.center;
    headerLabel.text = [diaryInSections.allKeys objectAtIndex:section];
    [headerView addSubview:headerLabel];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
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
