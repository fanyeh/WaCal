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
#import "DiaryEntryViewController.h"
#import "UIImage+Resize.h"

@interface DiaryCreateViewController () <filterImageDelegate,DiaryDelegate>
{
    CGRect diaryViewFrame;
    CGRect tabBarFrame;
    CGPoint _priorPoint;
    UIEdgeInsets collectionViewInset;
    CGFloat minimunCellSpace;
    CGFloat minimunLineSpace;
    BOOL deleteDiaryPhotos;
    NSArray *sizeArray;
    NSMutableArray *cellImageArray;
    NSMutableArray *resizedImageArray;
}
@property (weak, nonatomic) IBOutlet UIView *diaryDetailView;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetailTextView;

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
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 64, 320, 320) collectionViewLayout:layout];
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"DiaryPhotoCell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    collectionViewInset = UIEdgeInsetsMake(5, 5, 5, 5);
    minimunCellSpace = 5.0;
    minimunLineSpace = 5.0;
    
    // Get selected photos from delegate
    _selectedPhotos = [[self delegate]selectedPhotos];
    resizedImageArray = [[NSMutableArray alloc]init];
    cellImageArray = [[NSMutableArray alloc]init];

    // Perform initial face detection
    [self resizeSelectedPhotos];
    [self performSelectorInBackground:@selector(processFaceDetection) withObject:nil];
    
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(createNewDiaryEntry)];
    [_diaryDetailTextView addGestureRecognizer:tapGesture];
    
    // Add save button on navigation controller
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                              target:self
                                                                              action:@selector(addDiary)];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                               target:self
                                                                               action:@selector(editDiary)];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(cancelDiary)];
    
    self.navigationItem.rightBarButtonItems = @[editButton,saveButton];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)resizeSelectedPhotos
{
    for (int i = 0 ; i < [_selectedPhotos count]; i++) {
        UIImage *resizeImage =  [_selectedPhotos[i] resizeImageToSize:CGSizeMake(640, 1136)];
        [resizedImageArray addObject:resizeImage];
    }
}

- (void)processFaceDetection
{
    [self cellSizeArray];
    [cellImageArray removeAllObjects];
    // Process face detection
    for (int i = 0 ; i < [resizedImageArray count]; i++) {
        
        CGSize size = [sizeArray[i] CGSizeValue];
        
        UIImage *resizeImage = resizedImageArray[i];

        UIImage *cellImage = [resizeImage resizeWtihFaceDetect:size];
        [cellImageArray addObject:cellImage];
        
        [self performSelectorOnMainThread:@selector(reloadCollecitonView) withObject:nil waitUntilDone:YES];
    }
}

- (void)reloadCollecitonView
{
    [_collectionView reloadData];
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
//    if ([_selectedPhotos count] < 5)
//        _addPhotoBtn.hidden = NO;
//    else
//        _addPhotoBtn.hidden = YES;
    
    return [cellImageArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DiaryPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DiaryPhotoCell" forIndexPath:indexPath];
    [cell deletePhotoBadger:deleteDiaryPhotos];
    cell.photoView.frame = cell.contentView.bounds;
    if ([cellImageArray count] > 0)
        cell.photoView.image = cellImageArray[indexPath.row];

    // Add gesture to each cell
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self
                                                                                           action:@selector(enlargCell:)];
    [cell addGestureRecognizer:longPress];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (deleteDiaryPhotos) {
        [collectionView performBatchUpdates:^{
            [_selectedPhotos removeObjectAtIndex:indexPath.row];
            [resizedImageArray removeObjectAtIndex:indexPath.row];
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];

        } completion:^(BOOL finished) {
            deleteDiaryPhotos = NO;
            [self processFaceDetection];
        }];
    }
    else {
        DiaryPhotoViewController *photoViewController = [[DiaryPhotoViewController alloc]init];
        UIImage *photo = [_selectedPhotos objectAtIndex:indexPath.row];
        photoViewController.photoImage = photo;
        photoViewController.index = indexPath.row;
        photoViewController.delegate = self;
        [self.navigationController pushViewController:photoViewController animated:YES];
    }
}

#pragma mark - UICollectionViewDelegateFlowlayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSValue *cellSizeValue = sizeArray[indexPath.row];
    return [cellSizeValue CGSizeValue];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return collectionViewInset;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return minimunCellSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return minimunLineSpace;
}

- (void)cellSizeArray
{
    CGFloat sizeWidth = _collectionView.frame.size.width-collectionViewInset.left-collectionViewInset.right;
    CGFloat sizeHeight = _collectionView.frame.size.height-collectionViewInset.top-collectionViewInset.bottom;
    switch ([_selectedPhotos count]) {
        case 1:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, sizeHeight)]];
            break;
        case 2:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-minimunLineSpace)/2)]
                          ];
            break;
        case 3:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)]
                          ];
            break;
        case 4:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)]
                          ];
            break;
        case 5:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace*2)/3, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace*2)/3, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace*2)/3, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-minimunCellSpace)/2, (sizeHeight-minimunLineSpace)/2)]
                          ];
            break;
        default:
            break;
    }
}

#pragma mark - User Gestures And actions
- (IBAction)addPhotos:(id)sender {

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
                [resizedImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [self processFaceDetection];
            }];
        }
        else {
            [self.collectionView reloadItemsAtIndexPaths:@[currentCellIndexPath]];
        }
    }
}
- (IBAction)deletePhotos:(id)sender
{
    deleteDiaryPhotos = true;
    [_collectionView reloadData];
}

-(void)cancelDiary
{
    if (_diary)
        [[DiaryDataStore sharedStore]removeItem:_diary];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)addDiary
{
    _diary = [[DiaryDataStore sharedStore]createItem];
    
    // Store image in the ImageStore with this key
    FileManager *fm = [[FileManager alloc]initWithKey:_diary.diaryKey];
    
    for (int i=0;i < [_selectedPhotos count];i++) {
        [fm saveDiaryImage:_selectedPhotos[i] index:i];
    }
    
    // Create Image from collection view
    UIGraphicsBeginImageContext(_collectionView.bounds.size);
    UIGraphicsBeginImageContextWithOptions(_collectionView.bounds.size, YES, [UIScreen mainScreen].scale);
    [_collectionView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *collectionViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Save collection view image to document
    [fm saveCollectionImage:collectionViewImage];

    [_diary setThumbnailDataFromImage:collectionViewImage];
    [_diary setDiaryText:_diaryDetailTextView.text];
    [[DiaryDataStore sharedStore]saveChanges];
    
    // Send out notification for new diary added
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryChange" object:nil];
    
    // Back to Diary table view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)editDiary
{
    
}

- (void)createNewDiaryEntry
{
    DiaryEntryViewController *dvc = [[DiaryEntryViewController alloc]init];
    dvc.delegate = self;
    [self.navigationController pushViewController:dvc animated:YES];
}

#pragma mark - DiaryPhotoViewDelegate
-(void)filteredImage:(UIImage *)image index:(NSInteger)i
{
    _selectedPhotos[i] = image;
    [_collectionView reloadData];
}

#pragma mark - DiaryEntryViewDelegate
-(void)diaryDetails:(NSString *)details
{
    _diaryDetailTextView.text = details;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _collectionView.userInteractionEnabled = YES;
}
@end
