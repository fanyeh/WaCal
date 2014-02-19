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

@interface DiaryTableViewController ()
{
    UITableView *cloudTable;
    UITableView *localTable;
    NSMutableArray *cloudDiarys;
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
    
    UISegmentedControl *diaryFilter = [[UISegmentedControl alloc] initWithItems:@[@"Local", @"Cloud"]];
    [diaryFilter sizeToFit];
    self.navigationItem.titleView = diaryFilter;
    
    [diaryFilter addTarget:self
                         action:@selector(segmentControlAction:)
               forControlEvents:UIControlEventValueChanged];
    
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.tag = 0;
    localTable = self.tableView;
    
    cloudTable = [[UITableView alloc]initWithFrame:self.tableView.frame];
    cloudTable.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    cloudTable.dataSource = self;
    cloudTable.delegate = self;
    cloudTable.tag = 1;
    [cloudTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    cloudDiarys = [[NSMutableArray alloc]init];
    
    [[DropboxModel shareModel] linkToDropBox:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[DropboxModel shareModel] listAllCloudDiarys:^(NSMutableArray *diarysFromCloud) {
                cloudDiarys = diarysFromCloud;
                NSLog(@"Cloud diarys %@",cloudDiarys);
                [cloudTable reloadData];
            }];
        });
    } fromController:self];
}

- (void)segmentControlAction:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        NSLog(@"local table");
        self.tableView = localTable;
    } else {
        NSLog(@"Clound table");
        self.tableView = cloudTable;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView.tag == 0)
        return [[[DiaryDataStore sharedStore]allItems]count];
    else {
        NSLog(@"Cloud diary count %ld",[cloudDiarys count]);
        return [cloudDiarys count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (tableView.tag == 0) {
        // Configure the cell...
        DiaryData *d = [DiaryDataStore sharedStore].allItems[indexPath.row];
        cell.imageView.image = d.thumbnail;
        cell.textLabel.text = d.diaryText;
        return cell;
    } else {
        // Configure the cell...
        TempDiaryData *t = [cloudDiarys objectAtIndex:indexPath.row];
        cell.imageView.image = t.thumbnail;
        cell.textLabel.text = t.diaryText;
        return cell;
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 0) {
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
    // If talbeview.tag = 0
    // POP two buttons in row 1. View 2. Upload
    // For press view button
    DiaryViewController *controller = [[DiaryViewController alloc]init];
    controller.diaryData = [[DiaryDataStore sharedStore]allItems][indexPath.row];
    [self.navigationController pushViewController:controller animated:NO];
    // For presss uplaod button
    // push to new view controller which has several host to select for uplaod
    
    // If tableview.tag = 1
    // proceed downloading in background with download status circle show in cell
    // After download completed refresh get new list from host and refresh both local/cloud table
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
