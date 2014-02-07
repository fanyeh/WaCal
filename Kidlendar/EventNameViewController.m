//
//  EventNameViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventNameViewController.h"
#import "EventNameView.h"
#import "ProfileData.h"
#import "ProfileDataStore.h"
#import "ImageStore.h"
#import <EventKit/EventKit.h>

@interface EventNameViewController () <UITextFieldDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,UICollectionViewDelegate>
{
    EventNameView *nameView;
    UICollectionView *profileCollectionView;
}

@end

@implementation EventNameViewController

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
    // Do any additional setup after loading the view from its nib.
    
    nameView = [[EventNameView alloc]initWithFrame:CGRectMake(0, 0, 320, 352)];
    nameView.nameField.delegate = self;
    [nameView.nameField becomeFirstResponder];
    [self.view addSubview:nameView];
    
    // Setup Profile table
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    profileCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, 300, 60) collectionViewLayout:layout];
    [profileCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    profileCollectionView.dataSource = self;
    profileCollectionView.delegate = self;
    profileCollectionView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    ProfileData *p = ProfileDataStore.sharedStore.allItems[indexPath.row];
    cell.backgroundView = [[UIImageView alloc]initWithImage:p.thumbnail];
    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Returns number for items in datasource
    return [[[ProfileDataStore sharedStore]allItems]count];
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Put profile's index into event note
    _event.notes = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    ProfileData *p =  [[ProfileDataStore sharedStore]allItems][indexPath.row];
    nameView.nameField.text = p.name;
    UIImage *backgroundImage = [[ImageStore sharedStore]imageForKey:p.imageKey];
    nameView.backgroundImageView.image = backgroundImage;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(50,50);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 10, 5, 10);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    nameView.nameField.inputAccessoryView = profileCollectionView;
    return YES;
}


@end
