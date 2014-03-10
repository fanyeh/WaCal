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
    
//    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self  action:@selector(editDiaryTable)];
//    self.navigationItem.leftBarButtonItem = editButton;
//    self.navigationItem.leftBarButtonItem.tag = 0;

    
    // Date formatters
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"dd";
    weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (currentTableIsLocal)
        return [[[DiaryDataStore sharedStore]allItems]count];
    else {
        return [cloudDiarys count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryTableViewCell *cell = (DiaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryTableViewCell"];
    if (!cell)
        cell =[[DiaryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiaryTableViewCell"];
    cell.cellImageView.layer.cornerRadius = 5.0f;
    cell.cellImageView.layer.masksToBounds = YES;
    cell.cellView.layer.shadowColor = [[UIColor blackColor]CGColor];
    cell.cellView.layer.shadowOpacity = 0.5f;
    cell.cellView.layer.shadowOffset = CGSizeMake(2 , 2);

    // Configure the cell...
    DiaryData *d = [DiaryDataStore sharedStore].allItems[indexPath.row];
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
    cell.dateLabel.text = [dateFormatter stringFromDate:diaryDate];
    cell.weekdayLabel.adjustsFontSizeToFitWidth = YES;
    cell.weekdayLabel.text = [weekdayFormatter stringFromDate:diaryDate];
    cell.locationLabel.text = d.location;
    cell.diaryDetail.text = d.diaryText;
    cell.diarySubject.text = d.subject;
    
    if (d.diaryVideoPath) {
        cell.cellImageView.image = d.diaryVideoThumbnail;
    } else {
        cell.cellImageView.image = d.diaryImage;
    }
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (currentTableIsLocal) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // Delete the row from the data source
            DiaryData *d = [[[DiaryDataStore sharedStore]allItems]objectAtIndex:[indexPath row]];
            [[DiaryDataStore sharedStore] removeItem:d];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryChange" object:nil];
        }
        else if (editingStyle == UITableViewCellEditingStyleInsert) {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryViewController *controller = [[DiaryViewController alloc]init];
    controller.diaryData = [[DiaryDataStore sharedStore]allItems][indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 101; // 可在 XIB 檔案，點選 My Talbe View Cell 從 Size inspector 得知
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
