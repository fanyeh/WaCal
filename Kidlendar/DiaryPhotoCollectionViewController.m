//
//  DiaryPhotoCollectionViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/23.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryPhotoCollectionViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DiaryCreateViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "DiaryVideoViewController.h"

@interface DiaryPhotoCollectionViewController ()
{
    CGFloat minimumItemSpace;
    CGFloat minimumLineSpace;
    BOOL scrollToBottom;
}

@end

@implementation DiaryPhotoCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    minimumItemSpace = 2;
    minimumLineSpace = 2;
    self.tabBarController.tabBar.hidden = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.allowsMultipleSelection = YES;
    [[self collectionView] registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self navigationItem].rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(photoSelectDone)];
//    [self.navigationController setNavigationBarHidden:NO];
    scrollToBottom = NO;
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

-(void)viewDidLayoutSubviews
{
    if ([_assets count]>0 && !scrollToBottom) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([_assets count]-1) inSection:0];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        scrollToBottom = YES;
    }
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_assets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset =  [_assets objectAtIndex:indexPath.row];
    UIImageView *cellPhoto = [[UIImageView alloc]initWithImage:[UIImage imageWithCGImage: asset.thumbnail]];
    cell.backgroundView = cellPhoto;
    if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
        UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 50, 20)];
        timeLabel.text = [self formatInterval:[asset valueForProperty:ALAssetPropertyDuration]];
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.adjustsFontSizeToFitWidth = YES;
        [cell addSubview:timeLabel];
    }
    return cell;
}

- (NSString *) formatInterval: (NSNumber *) interval{
    unsigned long seconds = [interval integerValue];
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    
    NSMutableString * result = [NSMutableString new];
    
    if(hours)
        [result appendFormat: @"%ld:", hours];
    
    [result appendFormat: @"%2ld:", minutes];
    if (seconds < 10)
        [result appendFormat: @"0%ld", seconds];
    else
        [result appendFormat: @"%2ld", seconds];
    
    return result;
}

- (void)reloadCollectionView
{
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = (collectionView.bounds.size.width-(5*minimumItemSpace))/4;
    return CGSizeMake(cellWidth, cellWidth);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return minimumItemSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return minimumLineSpace;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (cell.isSelected)
    {
        //[self collectionView:collectionView didDeselectItemAtIndexPath:indexPath];
        cell.selected = NO;
        NSLog(@"Should not select");
        NSLog(cell.isSelected ? @"IS SELECTED : YES" : @"IS SELECTED : No");
        return NO;
    }
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderColor = [[UIColor blueColor]CGColor];
    cell.layer.borderWidth = 3.0f;
    ALAsset *asset =  [_assets objectAtIndex:indexPath.row];
    if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
        DiaryVideoViewController *dvc = [[DiaryVideoViewController alloc]init];
        dvc.asset = _assets[indexPath.row];
        [self.navigationController pushViewController:dvc animated:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.layer.borderColor = nil;
    cell.layer.borderWidth = 0.0f;
}

- (void)photoSelectDone
{
    NSArray *selectedPhotosIndexPath = [self.collectionView indexPathsForSelectedItems];
    NSMutableArray *photoAssets = [[NSMutableArray alloc]init];
    
    for (NSIndexPath *indexPath in selectedPhotosIndexPath) {
        ALAsset *asset =  [_assets objectAtIndex:indexPath.row];
       [photoAssets addObject:[UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage]];
    }
    DiaryCreateViewController *dvc = [[DiaryCreateViewController alloc]init];
    dvc.selectedPhotos = photoAssets;
    [self.navigationController pushViewController:dvc animated:YES];
}

@end
