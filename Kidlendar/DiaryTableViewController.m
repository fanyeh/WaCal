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
    
    [[DBAccountManager sharedManager] addObserver:self
                                            block:^(DBAccount *account) {
                                                //
                                                if (account.isLinked) {
                                                    
                                                    NSLog(@"Account linked from website");
                                                    [[DropboxModel shareModel] setupFileSystemAndStore:^(BOOL linked) {
                                                        if (linked) {
                                                            [[DBFilesystem sharedFilesystem] addObserver:self block:^{
                                                                //            DBSyncStatusDownloading	At least 1 file is currently downloading
                                                                //            DBSyncStatusUploading	At least 1 file is currently uploading
                                                                //            DBSyncStatusSyncing	Dropbox is currently sending new file information
                                                                //            DBSyncStatusActive	The Sync API is actively monitoring for changes from Dropbox. This will be true when there are pending uploads or downloads, when DBFiles are open, or when path observers are registered.
                                                                NSLog(@"File system status change %ld",[DBFilesystem sharedFilesystem].status);
                                                            }];
                                                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                [[DropboxModel shareModel] listAllCloudDiarys:^(NSMutableArray *diarysFromCloud) {
                                                                    cloudDiarys = diarysFromCloud;
                                                                    NSLog(@"Cloud diarys %@",cloudDiarys);
                                                                    [cloudTable reloadData];
                                                                }];
                                                                
                                                            });
                                                        }
                                                    }];
                                                }
                                                    
                                            }];
    
    [[DropboxModel shareModel] linkToDropBox:^(BOOL linked) {
        if (linked) {
            
            [[[DropboxModel shareModel]dataStore] addObserver:self block:^{
                NSLog(@"DS status %ld", [[DropboxModel shareModel]dataStore].status);
            }];
            
            [[DBFilesystem sharedFilesystem] addObserver:self block:^{
                NSLog(@"File system status change %ld",[DBFilesystem sharedFilesystem].status);
            }];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //            [[DropboxModel shareModel] listUndownloadDiary:^(NSMutableArray *diarysFromCloud) {
                //                cloudDiarys = diarysFromCloud;
                //                NSLog(@"Cloud diarys %@",cloudDiarys);
                //                [cloudTable reloadData];
                //            }];
                
                [[DropboxModel shareModel] listAllCloudDiarys:^(NSMutableArray *diarysFromCloud) {
                    cloudDiarys = diarysFromCloud;
                    NSLog(@"Cloud diarys %@",cloudDiarys);
                    [cloudTable reloadData];
                }];
                
            });
        }
        
    } fromController:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshCloud:) name:@"uploadComplete" object:nil];
}

- (void)refreshCloud:(NSNotification *)notification
{
    [[DropboxModel shareModel] listAllCloudDiarys:^(NSMutableArray *diarysFromCloud) {
        cloudDiarys = diarysFromCloud;
        NSLog(@"Cloud diarys %@",cloudDiarys);
        [cloudTable reloadData];
    }];
}

- (void)segmentControlAction:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        self.tableView = localTable;
    } else {
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
    if (!cell)
        cell =[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    if (tableView.tag == 0) {
        // Configure the cell...
        DiaryData *d = [DiaryDataStore sharedStore].allItems[indexPath.row];
        cell.imageView.image = d.thumbnail;
        cell.textLabel.text = d.diaryText;
        
        if (d.cloudRelationship.dropbox)
            cell.detailTextLabel.text = @"Dropbox Synced";
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
    if (tableView.tag == 0) {
        DiaryViewController *controller = [[DiaryViewController alloc]init];
        controller.diaryData = [[DiaryDataStore sharedStore]allItems][indexPath.row];
        [self.navigationController pushViewController:controller animated:NO];
    } else {
        // Download from cloud
        // Get tempdata
        TempDiaryData *t = [cloudDiarys objectAtIndex:indexPath.row];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[DropboxModel shareModel] downloadDiaryFromFilesystem:t.diaryKey complete:^(NSData *imageData) {
                UIImage *diaryImage = [UIImage imageWithData:imageData];
                DiaryData *d = [[DiaryDataStore sharedStore]createItem];
                d.diaryKey = t.diaryKey;
                d.diaryText = t.diaryText;
                [d setDiaryImageDataFromImage:diaryImage];
                [[DiaryDataStore sharedStore]saveChanges];
                
                [localTable reloadData];
                NSLog(@"Download completed");
            }];
        });
    }
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
