//
//  NewViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/13.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "NewViewController.h"
#import "CreateViewController.h"
#import "PhotoLoader.h"
#import "UIImage+Resize.h"
#import "FileManager.h"
#import "DiaryPhotoCell.h"
#import "DiaryPhotoViewController.h"
#import "PhotoCollectionHeaderView.h"

@interface NewViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,filterImageDelegate>
{
    // General collection view property
    UIEdgeInsets collectionViewInset;
    CGFloat minimunCellSpace;
    CGFloat minimunLineSpace;
    
    // Diary photo collection view property
    UICollectionView *diaryPhotosView; // Tag 0
    CGPoint _priorPoint;
    BOOL deleteDiaryPhotos;
    NSArray *sizeArray;
    NSMutableDictionary *selectedPhotoInfo;
    NSMutableArray *cellImageArray;
    NSMutableArray *resizedImageArray;
    NSMutableArray *selectedPhotoOrderingInfo;
    
    // Photo collection view property
    UICollectionView *photoCollectionView; // Tag 1
    BOOL scrollToBottom;
    NSMutableArray *photoAssets;
    NSString *assetGroupPropertyName;
    PhotoLoader *photoLoader;
    PhotoCollectionHeaderView *photoCollectionHeaderView;
    
    
}

@end

@implementation NewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

#pragma mark - View
#pragma mark

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Collection view properties
    collectionViewInset = UIEdgeInsetsMake(5, 5, 5, 5);
    minimunCellSpace = 5.0;
    minimunLineSpace = 5.0;
    
    // Set up diary photo collection view
    UICollectionViewFlowLayout *diaryFlowLayout = [[UICollectionViewFlowLayout alloc]init];

    diaryPhotosView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 44, 320, 320) collectionViewLayout:diaryFlowLayout];
    diaryPhotosView.delegate = self;
    diaryPhotosView.dataSource = self;
    diaryPhotosView.tag = 0;
    diaryPhotosView.allowsMultipleSelection = NO;
    [diaryPhotosView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"DiaryPhotoCell"];
    [self.view addSubview:diaryPhotosView];
    selectedPhotoInfo = [[NSMutableDictionary alloc]init];
    resizedImageArray = [[NSMutableArray alloc]init];
    cellImageArray = [[NSMutableArray alloc]init];
    selectedPhotoOrderingInfo = [[NSMutableArray alloc]init];
    
    // Set up photo album collection view
    UICollectionViewFlowLayout *photoFlowLayout = [[UICollectionViewFlowLayout alloc]init];
    photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 376, 320, 320) collectionViewLayout:photoFlowLayout];
    photoCollectionView.delegate = self;
    photoCollectionView.dataSource = self;
    photoCollectionView.tag = 1;
    [photoCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [photoCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [photoCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];

    photoCollectionView.allowsMultipleSelection = YES;
    
    [self.view addSubview:photoCollectionView];
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

#pragma mark - Diary photo collection view relate
#pragma mark

-(UIImage *)getPhotoWithUID:(NSString *)uid
{
    NSMutableDictionary *selectedPhotoDict =  [selectedPhotoInfo objectForKey:assetGroupPropertyName];
    NSArray *selectedPhotoWithUID = [selectedPhotoDict objectForKey:uid];
    return selectedPhotoWithUID[1];
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
        
        [self performSelectorOnMainThread:@selector(reloadDiaryPhotosView) withObject:nil waitUntilDone:YES];
    }
}

- (void)reloadDiaryPhotosView
{
    [diaryPhotosView reloadData];
}

- (void)deletePhoto {
    deleteDiaryPhotos = true;
    [diaryPhotosView reloadData];
}

- (void)cellSizeArray
{
    CGFloat sizeWidth = diaryPhotosView.frame.size.width-collectionViewInset.left-collectionViewInset.right;
    CGFloat sizeHeight = diaryPhotosView.frame.size.height-collectionViewInset.top-collectionViewInset.bottom;
    switch ([selectedPhotoOrderingInfo count]) {
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
        NSIndexPath *touchedCellPath = [diaryPhotosView indexPathForItemAtPoint:CGPointMake(sender.view.center.x, sender.view.center.y)];
        NSIndexPath *currentCellIndexPath = [diaryPhotosView indexPathForCell:cell];
        
        if (touchedCellPath != currentCellIndexPath) {
            [self.view bringSubviewToFront:sender.view];
            [diaryPhotosView performBatchUpdates:^{
                [diaryPhotosView moveItemAtIndexPath:currentCellIndexPath toIndexPath:touchedCellPath];
                [diaryPhotosView moveItemAtIndexPath:touchedCellPath toIndexPath:currentCellIndexPath];
                
            } completion:^(BOOL finished) {
                // Also need to adjust index position in data source
                [selectedPhotoOrderingInfo exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [resizedImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [self processFaceDetection];
            }];
        }
        else {
            [diaryPhotosView reloadItemsAtIndexPaths:@[currentCellIndexPath]];
        }
    }
}

#pragma mark -DiaryPhotoViewDelegate

-(void)filteredImage:(UIImage *)image index:(NSInteger)i
{
    NSArray *ImageInfo =  selectedPhotoOrderingInfo[i];
    NSMutableDictionary *selectedPhotoDict = [selectedPhotoInfo objectForKey:ImageInfo[1]];
    [selectedPhotoDict setObject:image forKey:ImageInfo[0]];
    [diaryPhotosView cellForItemAtIndexPath:ImageInfo[0]];
}

#pragma mark -Diary relate

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
    
    for (int i=0;i < [selectedPhotoOrderingInfo count];i++) {
        // TODO
    }
    
    // Create Image from collection view
    UIGraphicsBeginImageContextWithOptions(diaryPhotosView.bounds.size, YES, [UIScreen mainScreen].scale);
    [diaryPhotosView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *collectionViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Save collection view image to document
    [fm saveCollectionImage:collectionViewImage];
    
    [_diary setThumbnailDataFromImage:collectionViewImage];
    [[DiaryDataStore sharedStore]saveChanges];
    
    // Send out notification for new diary added
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryChange" object:nil];
    
    // Back to Diary table view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Photo collection view relate
#pragma mark

- (void)reloadPhotoCollectionView
{
    NSArray *sourceKeys = photoLoader.sourceDictionary.allKeys;
    
    // Set up dictionary to preserve image and index path and album name
    for (NSString *key in sourceKeys) {
        NSMutableDictionary *photoGroupDict = [[NSMutableDictionary alloc]init];
        [selectedPhotoInfo setValue:photoGroupDict forKey:key];
    }
    
    NSString *sourceKey = sourceKeys[0];
    assetGroupPropertyName = sourceKey;
    photoAssets = [photoLoader.sourceDictionary objectForKey:sourceKey];
    [photoCollectionView reloadData];
}

-(void)viewDidLayoutSubviews
{
    if ([photoAssets count] > 0 && !scrollToBottom) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([photoAssets count]-1) inSection:0];
        [photoCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        scrollToBottom = YES;
    }
}

- (void)selectedPhoto:(NSIndexPath *)indexPath
{
    ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
    // Retrieve the image orientation from the ALAsset
    UIImageOrientation orientation = UIImageOrientationUp;
    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
    if (orientationValue != nil) {
        orientation = [orientationValue intValue];
    }
    
    UIImage* image = [UIImage imageWithCGImage:[asset.defaultRepresentation fullResolutionImage]
                                         scale:1 orientation:orientation];
    
    // Put image selected photo dictionary
    NSMutableDictionary *selectedPhotoDict =  [selectedPhotoInfo objectForKey:assetGroupPropertyName];
    [selectedPhotoDict setObject:image forKey:indexPath];
    
    // Create info array for diary collection view
    NSArray *imageInfo = @[indexPath,assetGroupPropertyName];
    [selectedPhotoOrderingInfo addObject:imageInfo];

    // Resize the image
    UIImage *resizedImage =  [image resizeImageToSize:CGSizeMake(640, 1136)];
    [resizedImageArray addObject:resizedImage];
    
    // Perform face detection and setup diary collection view
    [self performSelectorInBackground:@selector(processFaceDetection) withObject:nil];
}
#pragma mark - Collection Views
#pragma mark

#pragma mark -UICollectionViewDataSource
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

#pragma mark -UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==0) {
        if (deleteDiaryPhotos) {
            [collectionView performBatchUpdates:^{
                // Get image info index path
                NSArray *imageInfo = selectedPhotoOrderingInfo[indexPath.row];
                
                // Remove image from selectedPhotoDict and selectedPhotoOrderingInfo
                [self removePhotoWithIndexPath:imageInfo[0]];
                
                // Remove image from resize image array
                [resizedImageArray removeObjectAtIndex:indexPath.row];
                
                [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                
            } completion:^(BOOL finished) {
                deleteDiaryPhotos = NO;
                [self processFaceDetection];
            }];
        }
        else {
            DiaryPhotoViewController *photoViewController = [[DiaryPhotoViewController alloc]init];
            
            // Get image from selectedPhotoInfo
            UIImage *photo = [self getPhotoWithImageInfo:[selectedPhotoOrderingInfo objectAtIndex:indexPath.row]];
            photoViewController.photoImage = photo;
            photoViewController.index = indexPath.row;
            photoViewController.delegate = self;
            [self.navigationController pushViewController:photoViewController animated:YES];
        }
        
    }
    // Photo collection view select
    else {
        [self selectedPhoto:indexPath];
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderColor = [[UIColor blueColor]CGColor];
        cell.layer.borderWidth = 3.0f;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==1) {
        [self removePhotoWithIndexPath:indexPath];
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        cell.layer.borderColor = nil;
        cell.layer.borderWidth = 0.0f;
    }
}

#pragma mark -Remove Photo

- (void)removePhotoWithIndexPath:(NSIndexPath *)path
{
    for (NSArray *imageInfo in selectedPhotoOrderingInfo) {
        // ImageInfo[0] = indexpath
        // ImageInfo[1] = assset group name
        if (imageInfo[0] == path) {

            // Remove image from selectedPhotoDict - dict selected based on assetgroup name
            NSMutableDictionary *selectedPhotoDict = [selectedPhotoInfo objectForKey:imageInfo[1]];
            [selectedPhotoDict removeObjectForKey:path];
            
            // Remove image from resize image array
            NSUInteger index = [selectedPhotoOrderingInfo indexOfObject:imageInfo];
            [resizedImageArray removeObjectAtIndex:index];

            // Remove image info from ordering info
            [selectedPhotoOrderingInfo removeObject:imageInfo];
            
            [self processFaceDetection];
            break;
        }
    }
    
    // Reload diary view data
    [diaryPhotosView reloadData];
}

#pragma mark -Get Photo

- (UIImage *)getPhotoWithImageInfo:(NSArray *)imageInfo
{
    // Remove image from selectedPhotoDict - dict selected based on assetgroup name
    NSMutableDictionary *selectedPhotoDict = [selectedPhotoInfo objectForKey:imageInfo[1]];
    UIImage *image = [selectedPhotoDict objectForKey:imageInfo[0]];
    return image;
}


#pragma mark -UICollectionViewDelegateFlowlayout

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

#pragma mark - Memory Warning
#pragma mark

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end