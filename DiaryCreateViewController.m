//
//  DiaryBrowseViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryCreateViewController.h"
#import "DiaryPhotoCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "DiaryCreateViewController.h"
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "DiaryPhotoViewController.h"
#import "MediaTableViewController.h"
#import "FileManager.h"

@interface DiaryCreateViewController ()
{
    CGRect diaryViewFrame;
    CGRect tabBarFrame;
    CGPoint _priorPoint;
}

@property (weak, nonatomic) IBOutlet UITextField *diarySubject;
@end

@implementation DiaryCreateViewController

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

    // Initiate collection view
    [_collectionView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"PhotoCell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    // Initiate subject field
    _diarySubject.delegate = self;
    
    // Add save button on navigation controller
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                              target:self
                                                                              action:@selector(addDiary)];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(cancelDiary)];
    UIBarButtonItem *backupButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                               target:self
                                                                               action:@selector(backupDiary)];

    self.navigationItem.rightBarButtonItems = @[backupButton,saveButton];
    self.navigationItem.leftBarButtonItem = backButton;
    
    // Hide collection view and diary view before user selected profile
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Returns number for items in datasource
    return [_selectedPhotos count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
        DiaryPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        UIImage *photo = [_selectedPhotos objectAtIndex:indexPath.row];
        CGSize photoSize = [self adjustPhotoSize:photo];
        
        // Resize photo 
        //cell.photoView.image = [photo resizeWtihFaceDetect:photoSize];
        cell.photoView.image = [photo resizeImageToSize:photoSize];
        [cell.photoView sizeToFit];
        
        // Add gesture to each cell
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self
                                                                                               action:@selector(enlargCell:)];
        [cell addGestureRecognizer:longPress];
        return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryPhotoViewController *photoViewController = [[DiaryPhotoViewController alloc]init];
    UIImage *photo = [_selectedPhotos objectAtIndex:indexPath.row];
    photoViewController.photoImage = photo;
    photoViewController.index = indexPath.row;
    photoViewController.PassFilteredImageDelegate = self;
    [self.navigationController pushViewController:photoViewController animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowlayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
        UIImage *photo = [_selectedPhotos objectAtIndex:indexPath.row];
        
        // Reset cell size
        CGSize retval = [self adjustPhotoSize:photo];
        //retval.height += 4; retval.width += 4;
        return retval;
}

- (CGSize)adjustPhotoSize:(UIImage *)photo
{
    CGSize photoSize;
    // Option 1 : 6 square photos
    photoSize = CGSizeMake(150, 200);

    return photoSize;
}

#pragma mark - User Gestures And actions
- (IBAction)selectMediaType:(id)sender {
    MediaTableViewController *mvc = [[MediaTableViewController alloc]init];
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)enlargCell:(UILongPressGestureRecognizer *)sender
{
    // Enlarge cell when long pressed
    UICollectionViewCell *cell = (UICollectionViewCell *)sender.view;
    if (sender.state == UIGestureRecognizerStateBegan) {
        cell.transform = CGAffineTransformScale(cell.transform, 1.1 , 1.1);
    }
    
    // Pan the cell
    CGPoint point = [sender locationInView:sender.view.superview];
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint center = sender.view.center;
        center.x += point.x - _priorPoint.x;
        center.y += point.y - _priorPoint.y;
        sender.view.center = center;
    }
    _priorPoint = point;
    
    // Resize cell back when state ended or cancelled
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)
    {
        cell.transform = CGAffineTransformIdentity;
        NSIndexPath *touchedCellPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(sender.view.center.x, sender.view.center.y)];
        NSIndexPath *currentCellIndexPath = [self.collectionView indexPathForCell:cell];

        if (touchedCellPath != currentCellIndexPath) {
            [self.view bringSubviewToFront:sender.view];
            [self.collectionView performBatchUpdates:^{
                [self.collectionView moveItemAtIndexPath:currentCellIndexPath toIndexPath:touchedCellPath];
                [self.collectionView moveItemAtIndexPath:touchedCellPath toIndexPath:currentCellIndexPath];
                
            } completion:^(BOOL finished) {
                // Also need to adjust index position in data source
                [_selectedPhotos exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [self.collectionView reloadData];
            }];
        }
        else {
            [self.collectionView reloadItemsAtIndexPaths:@[currentCellIndexPath]];
        }
    }
}

- (IBAction)openDiaryPhotos:(id)sender {
    
    // Make collection view into image
    UIGraphicsBeginImageContext(_collectionView.bounds.size);
    [_collectionView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    DiaryPhotoViewController *photoViewController = [[DiaryPhotoViewController alloc]init];
    photoViewController.photoImage = viewImage;
    [self.navigationController pushViewController:photoViewController animated:YES];
}

-(void)cancelDiary
{
    if (_diary)
        [[DiaryDataStore sharedStore]removeItem:_diary];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)addDiary
{
    // dismiss keybaord
    _diary = [[DiaryDataStore sharedStore]createItem];
    
    // Save Diary
    _diary.subject = _diarySubject.text;
    
    // Store image in the ImageStore with this key
    FileManager *fm = [[FileManager alloc]initWithKey:_diary.diaryKey];
    
    for (int i=0;i < [_selectedPhotos count];i++) {
        [fm saveDiaryImage:_selectedPhotos[i] index:i];
    }
    
    // Create Image from collection view
    UIGraphicsBeginImageContext(_collectionView.bounds.size);
    [_collectionView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *collectionViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Save collection view image to document
    [fm saveCollectionImage:collectionViewImage];

    [_diary setThumbnailDataFromImage:collectionViewImage];
    [[DiaryDataStore sharedStore]saveChanges];
    
    // Back to Diary table view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)backupDiary
{
    // Diary file system structure should be "/kidlendar/profile name/create date time - diary title/filename"
}

#pragma mark - PassSelectedPhotosDelegate

-(void)selectedPhotos:(NSMutableArray *)selectedPhotos
{
    NSLog(@"select");

    _selectedPhotos = selectedPhotos;
    [self.collectionView reloadData];
}

#pragma mark - PassFilteredImage

-(void)filteredImage:(UIImage *)image index:(NSInteger)i
{
    NSLog(@"filter");
    _selectedPhotos[i] = image;
    [self.collectionView reloadData];
}

#pragma  mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_diarySubject resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _collectionView.userInteractionEnabled = YES;
}
@end
