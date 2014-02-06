//
//  MediaTableViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "MediaTableViewController.h"
#import "DiaryPhotoCollectionViewController.h"

@interface MediaTableViewController ()
{
    NSArray *mediaDict;
    NSMutableDictionary *photoDict;
    NSMutableDictionary *videoDict;
}

@end

@implementation MediaTableViewController

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
    [self preparePhotos];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
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
    return [mediaDict[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSDictionary *p = mediaDict[indexPath.section];
    NSArray *keys = p.allKeys;
    NSMutableArray *group = [p objectForKey:keys[indexPath.row]];
    cell.textLabel.text = keys[indexPath.row];
    ALAsset *a = [group lastObject];
    cell.imageView.image = [UIImage imageWithCGImage:a.thumbnail];    
    return cell;
}

#pragma mark - Media Selection

- (void)preparePhotos
{
    _assetGroups = [[NSMutableArray alloc] init];
    _library = [[ALAssetsLibrary alloc] init];
    photoDict = [[NSMutableDictionary alloc]init];
    videoDict = [[NSMutableDictionary alloc]init];
    __block NSMutableArray *assets;

    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^ {
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            if (group == nil)
                return;
            
            // added fix for camera albums order
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            
            // Get all photos from library
            assets = [[NSMutableArray alloc]init];
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop){
                if (asset) {
                    [assets addObject:asset];
                }
            }];
            if ([assets count]>0)
                [photoDict setObject:assets forKey:sGroupPropertyName];
            
            // Get all videos from asset library
            assets = [[NSMutableArray alloc]init];
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop){
                if (asset)
                    [assets addObject:asset];
            }];
            if ([assets count]>0)
                [videoDict setObject:assets forKey:sGroupPropertyName];

            // Reload Album
            [self performSelectorOnMainThread:@selector(reloadTableView)
                                   withObject:nil
                                waitUntilDone:YES];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"A problem occured %@", [error description]);
        };
        
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                    usingBlock:assetGroupEnumerator
                                  failureBlock:assetGroupEnumberatorFailure];
        
    });
}

- (void)reloadTableView
{
    mediaDict = @[photoDict,videoDict];
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section==0) {
        return @"allPhoto";
    }
    else {
        return @"allVideo";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    DiaryPhotoCollectionViewController *dvc = [[DiaryPhotoCollectionViewController alloc]initWithCollectionViewLayout:layout];
    NSDictionary *group = mediaDict[indexPath.section];
    NSArray *keys = group.allKeys;
    dvc.assets =[group objectForKey:keys[indexPath.row]];
    [self.navigationController pushViewController:dvc animated:YES];
}


@end
