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
#import "DropboxModel.h"
#import "TempDiaryData.h"
#import <Dropbox/Dropbox.h>
#import "CloudData.h"
#import "DiaryTableViewCell.h"
#import "LocationData.h"
#import "LocationDataStore.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@interface DiaryTableViewController ()
{
    UITableView *cloudTable;
    UITableView *localTable;
    NSMutableDictionary *cloudDiarys;
    BOOL currentTableIsLocal;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *weekdayFormatter;
    UILabel *headerLabel;
    UISegmentedControl *diaryFilter;
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
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(createDiary)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self  action:@selector(editDiaryTable)];
    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.leftBarButtonItem.tag = 0;
    
    diaryFilter = [[UISegmentedControl alloc] initWithItems:@[@"Local", @"Cloud"]];
    [diaryFilter sizeToFit];
    self.navigationItem.titleView = diaryFilter;
    
    [diaryFilter addTarget:self
                         action:@selector(segmentControlAction:)
               forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"DiaryTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"DiaryTableViewCell"];
        
    self.tableView.backgroundColor =  [UIColor clearColor];
    
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerView.backgroundColor = [UIColor whiteColor];
    headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 320, 44)];
    headerLabel.text = @"February 2014";
    headerLabel.textColor = Rgb2UIColor(33, 138, 251);
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = [UIFont fontWithName:@"Avenir" size:20];
    headerLabel.center = headerView.center;
    
    [headerView addSubview:headerLabel];
    
    self.tableView.tableHeaderView = headerView;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    cloudDiarys = [[NSMutableDictionary alloc]init];
    
    // Current table
    currentTableIsLocal = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCloud:) name:@"uploadComplete" object:nil];
    
    dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"dd";
    weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
}

- (void)refreshCloud:(NSNotification *)notification
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[DropboxModel shareModel] listAllCloudDiarys:^(NSMutableDictionary *diarysFromCloud) {
            cloudDiarys = diarysFromCloud;
            NSLog(@"Cloud diarys %@",cloudDiarys);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    });
}

//- (void)fetchFromCloud
//{
//    [[DropboxModel shareModel] linkToDropBox:^(BOOL linked) {
//        if (linked) {
//            
//            [[DBFilesystem sharedFilesystem] addObserver:self block:^{
//                NSLog(@"File system status change %ld",(unsigned long)[DBFilesystem sharedFilesystem].status);
//            }];
//            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                            [[DropboxModel shareModel] listUndownloadDiary:^(NSMutableDictionary *diarysFromCloud) {
//                                cloudDiarys = diarysFromCloud;
//                                [self.tableView reloadData];
//                            }];
//            });
//        }
//        
//    } fromController:self];
//
//}

//- (void)listUndownloadDairy
//{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [[DropboxModel shareModel] listUndownloadDiary:^(NSMutableDictionary *diarysFromCloud) {
//            cloudDiarys = diarysFromCloud;
//            [self.tableView reloadData];
//        }];
//    });
//}

- (void)segmentControlAction:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        currentTableIsLocal = YES;
        headerLabel.text = @"Local";
    } else {
        currentTableIsLocal = NO;
        headerLabel.text = @"Cloud";
        [[DropboxModel shareModel]linkToDropBox:^(BOOL linked) {
            if (linked) {
                [self refreshCloud:nil];
            }
        } fromController:self];
    }
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    [[self.tabBarController.tabBar.items objectAtIndex:1]setBadgeValue:nil];
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

    // Local cell
    if (currentTableIsLocal) {
        DiaryTableViewCell *cell = (DiaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryTableViewCell"];
        if (!cell)
            cell =[[DiaryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiaryTableViewCell"];

        // Configure the cell...
        DiaryData *d = [DiaryDataStore sharedStore].allItems[indexPath.row];
//        cell.imageView.image = d.thumbnail;
//        cell.textLabel.text = d.diaryText;
//        
//        if (d.cloudRelationship.dropbox)
//            cell.detailTextLabel.text = @"Dropbox Synced";
//        return cell;
        cell.cellImageView.layer.cornerRadius = 5.0f;
        cell.cellImageView.layer.masksToBounds = YES;
        cell.cellImageView.image = d.diaryImage;
        cell.cellView.layer.cornerRadius = 5.0f;
        cell.cellView.layer.shadowColor = [[UIColor blackColor]CGColor];
        cell.cellView.layer.shadowOpacity = 0.5f;
        cell.cellView.layer.shadowOffset = CGSizeMake(2 , 2);
        
        NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:d.dateCreated];
        cell.dateLabel.text = [dateFormatter stringFromDate:diaryDate];
        cell.weekdayLabel.adjustsFontSizeToFitWidth = YES;
        cell.weekdayLabel.text = [weekdayFormatter stringFromDate:diaryDate];
        cell.locationLabel.text = d.location;
        cell.diaryDetail.text = d.diaryText;
        cell.diarySubject.text = d.subject;
        return cell;

    }
    // Cloud cell
    else {
        DiaryTableViewCell *cell = (DiaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryTableViewCell"];
        if (!cell)
            cell =[[DiaryTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiaryTableViewCell"];
        
        cell.cellImageView.layer.cornerRadius = 5.0f;
        cell.cellImageView.layer.masksToBounds = YES;
        cell.cellView.layer.cornerRadius = 5.0f;
        cell.cellView.layer.shadowColor = [[UIColor blackColor]CGColor];
        cell.cellView.layer.shadowOpacity = 0.5f;
        cell.cellView.layer.shadowOffset = CGSizeMake(2 , 2);
//
        TempDiaryData *t = [[cloudDiarys allValues] objectAtIndex:indexPath.row];
//        NSLog(@"T %@",t);
        NSDictionary *diaryData = t.diaryData;
        NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[(NSString *)[diaryData objectForKey:@"dateInterval"] doubleValue]];
        cell.dateLabel.text = [dateFormatter stringFromDate:diaryDate];
        cell.weekdayLabel.adjustsFontSizeToFitWidth = YES;
        cell.weekdayLabel.text = [weekdayFormatter stringFromDate:diaryDate];
        cell.cellImageView.image =t.thumbnail;
        cell.locationLabel.text = [diaryData objectForKey:@"diaryLocationName"];
        cell.diaryDetail.text = [diaryData objectForKey:@"diaryText"];
        cell.diarySubject.text = [diaryData objectForKey:@"diarySubject"];

        return cell;
    }
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
    if (currentTableIsLocal) {
        DiaryViewController *controller = [[DiaryViewController alloc]init];
        controller.diaryData = [[DiaryDataStore sharedStore]allItems][indexPath.row];
        [self.navigationController pushViewController:controller animated:NO];
    } else {
        // Download from cloud
        // Get tempdata
        TempDiaryData *t = [[cloudDiarys allValues] objectAtIndex:indexPath.row];
        BOOL download = YES;
        // Check if diary already exist
        for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
            if ([d.diaryKey isEqualToString:t.diaryKey]) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Diary Exist"
                                                               message:@"You already have this diary in phone"
                                                              delegate:self cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil, nil];
                [alert show];
                download = NO;
                break;
            }
        }
        if(download) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[DropboxModel shareModel] downloadDiaryFromFilesystem:t.diaryKey complete:^(NSData *imageData) {
                    UIImage *diaryImage = [UIImage imageWithData:imageData];
                    
                    DiaryData *d = [[DiaryDataStore sharedStore]createItem];
                    NSDictionary *diaryData = t.diaryData;
                    
                    d.diaryKey = t.diaryKey;
                    d.subject = [diaryData objectForKey:@"diarySubject"];
                    d.location =  [diaryData objectForKey:@"diaryLocationName"];
                    d.diaryText =  [diaryData objectForKey:@"diaryText"];
                    d.dateCreated = [(NSString *)[diaryData objectForKey:@"dateInterval"] doubleValue];
                    [d setDiaryImageDataFromImage:diaryImage];
                    [[DiaryDataStore sharedStore]saveChanges];
                    
                    NSDictionary *l = [diaryData objectForKey:@"diaryLocatinoCoordinate"];
                    if(l) {
                        LocationData *diaryLocation = [[LocationDataStore sharedStore]createItemWithKey:t.diaryKey];
                        diaryLocation.longitude = [(NSString *)[l objectForKey:@"longitude"] doubleValue];
                        diaryLocation.latitude = [(NSString *)[l objectForKey:@"latitude"] doubleValue];
                    }
                    
                    //                [self listUndownloadDairy];
                    [localTable reloadData];
                    diaryFilter.selectedSegmentIndex = 0;
                    currentTableIsLocal = YES;
                    NSLog(@"Download completed");
                }];
            });
        }
    }
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
