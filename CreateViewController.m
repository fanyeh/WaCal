//
//  CreateViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/13.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "CreateViewController.h"
#import "PhotoLoader.h"

@interface CreateViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    UICollectionView *diaryPhotosView; // Tag 0
    UIEdgeInsets collectionViewInset;
    CGFloat minimunCellSpace;
    CGFloat minimunLineSpace;

    UICollectionView *photoCollectionView; // Tag 1
    BOOL scrollToBottom;
    NSMutableArray *photoAssets;
    
    
    CGRect diaryViewFrame;
    CGRect tabBarFrame;
    CGPoint _priorPoint;
    BOOL deleteDiaryPhotos;
    NSArray *sizeArray;
    NSMutableArray *cellImageArray;
    NSMutableArray *resizedImageArray;

    PhotoLoader *photoLoader;

}
@property (weak, nonatomic) IBOutlet UIToolbar *diaryPhotosToolBar;

@end

@implementation CreateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
           }
    return self;
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


- (void)reloadPhotoCollectionView
{
    photoAssets = [photoLoader sourceArray][0];
    [photoCollectionView reloadData];
}


-(void)viewDidLayoutSubviews
{
    if ([photoAssets count]>0 && !scrollToBottom) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([photoAssets count]-1) inSection:0];
        [photoCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        scrollToBottom = YES;
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Collection view properties
    collectionViewInset = UIEdgeInsetsMake(5, 5, 5, 5);
    minimunCellSpace = 5.0;
    minimunLineSpace = 5.0;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    
    // Set up diary photo collection view
    diaryPhotosView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 44, 320, 320) collectionViewLayout:flowLayout];
    diaryPhotosView.delegate = self;
    diaryPhotosView.dataSource = self;
    diaryPhotosView.tag = 0;
    // Get selected photos from delegate
    _selectedPhotos = [[self delegate]selectedPhotos];
    resizedImageArray = [[NSMutableArray alloc]init];
    cellImageArray = [[NSMutableArray alloc]init];
    
    // Perform initial face detection
    [self resizeSelectedPhotos];
    [self performSelectorInBackground:@selector(processFaceDetection) withObject:nil];
    
    // Set up photo album collection view
    photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 376, 320, 320) collectionViewLayout:flowLayout];
    photoCollectionView.delegate = self;
    photoCollectionView.dataSource = self;
    photoCollectionView.tag = 1;
    //photoAssets = [[NSMutableArray alloc]init];
    scrollToBottom = NO;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPhotoCollectionView) name:@"loadLibraySourceDone" object:nil];
    
    photoLoader = [[PhotoLoader alloc]initWithSourceType:kSourceTypePhoto];

}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (IBAction)deletePhoto:(id)sender {
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

- (IBAction)faceDetectionEnable:(id)sender {
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource
// Tag 0 = diary , 1 = photo

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView.tag==0) {
        return [cellImageArray count];
    } else {
        return [photoAssets count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==0) {
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
        
    } else {
        static NSString *CellIdentifier = @"Cell";
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        UIImageView *cellPhoto = [[UIImageView alloc]initWithImage:[UIImage imageWithCGImage: asset.thumbnail]];
        cell.backgroundView = cellPhoto;
        return cell;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==0) {
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
        
    } else {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderColor = [[UIColor blueColor]CGColor];
        cell.layer.borderWidth = 3.0f;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (collectionView.tag==0) {
        
    } else {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderColor = nil;
        cell.layer.borderWidth = 0.0f;
    }
}


#pragma mark - UICollectionViewDelegateFlowlayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==0) {
        NSValue *cellSizeValue = sizeArray[indexPath.row];
        return [cellSizeValue CGSizeValue];
    } else {
        CGFloat cellWidth = (collectionView.bounds.size.width-(5*minimunCellSpace))/4;
        return CGSizeMake(cellWidth, cellWidth);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return collectionViewInset;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return minimunLineSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return minimunCellSpace;
}

@end
