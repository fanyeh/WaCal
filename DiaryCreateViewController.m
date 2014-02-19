//
//  NewViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/13.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryCreateViewController.h"
#import "CreateViewController.h"
#import "PhotoLoader.h"
#import "UIImage+Resize.h"
#import "FileManager.h"
#import "DiaryPhotoCell.h"
#import "DiaryPhotoViewController.h"
#import "DiaryEntryViewController.h"

@interface DiaryCreateViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,filterImageDelegate,UITableViewDataSource,UITableViewDelegate>
{
    // Diary photo collection view property
    UIEdgeInsets diaryCollectionViewInset;
    CGFloat diaryMinimunCellSpace;
    CGFloat diaryMinimunLineSpace;
    
    UICollectionView *diaryPhotosView; // Tag 0
    CGPoint _priorPoint;
    BOOL deleteDiaryPhotos;
    NSArray *sizeArray;
    NSMutableDictionary *selectedPhotoInfo;
    NSMutableArray *cellImageArray;
    NSMutableArray *fullScreenImageArray;
    NSMutableArray *selectedPhotoOrderingInfo;
    
    // Photo collection view property
    UIEdgeInsets photoCollectionViewInset;
    CGFloat photoMinimunCellSpace;
    CGFloat photoMinimunLineSpace;

    UICollectionView *photoCollectionView; // Tag 1
    BOOL scrollToBottom;
    NSMutableArray *photoAssets;
    NSString *assetGroupPropertyName;
    PhotoLoader *photoLoader;
    CGFloat swipeOffset;
    UITableView *photoAlbumTable;
    
    UIActivityIndicatorView *faceDetectingActivity;
    BOOL faceDetectionEnabled;
}

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

#pragma mark - View
#pragma mark

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Set up diary photo collection view
    diaryCollectionViewInset = UIEdgeInsetsMake(5, 0, 5, 0);
    diaryMinimunCellSpace = 5.0;
    diaryMinimunLineSpace = 5.0;

    UICollectionViewFlowLayout *diaryFlowLayout = [[UICollectionViewFlowLayout alloc]init];
    diaryPhotosView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 44, 320, 320) collectionViewLayout:diaryFlowLayout];
    diaryPhotosView.delegate = self;
    diaryPhotosView.dataSource = self;
    diaryPhotosView.tag = 0;
    diaryPhotosView.allowsMultipleSelection = NO;
    [diaryPhotosView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"DiaryPhotoCell"];
    selectedPhotoInfo = [[NSMutableDictionary alloc]init];
    fullScreenImageArray = [[NSMutableArray alloc]init];
    cellImageArray = [[NSMutableArray alloc]init];
    selectedPhotoOrderingInfo = [[NSMutableArray alloc]init];
    [self.view addSubview:diaryPhotosView];

    // Scroll control for photo collection view
    UIView *scroller = [[UIView alloc]initWithFrame:CGRectMake(0, 364 , 320, 44)];
    scroller.backgroundColor = [UIColor grayColor];
    UISwipeGestureRecognizer *swipGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipePhotoCollection:)];
    swipGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [scroller addGestureRecognizer:swipGesture];
    [self.view addSubview:scroller];

    // Set up photo album collection view
    photoCollectionViewInset = UIEdgeInsetsMake(2, 0, 2, 0);
    photoMinimunCellSpace = 1;
    photoMinimunLineSpace = 1;

    UICollectionViewFlowLayout *photoFlowLayout = [[UICollectionViewFlowLayout alloc]init];
    photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 408, 320, self.view.frame.size.height-44) collectionViewLayout:photoFlowLayout];
    photoCollectionView.delegate = self;
    photoCollectionView.dataSource = self;
    photoCollectionView.tag = 1;
    photoCollectionView.showsVerticalScrollIndicator = NO;
    [photoCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    photoCollectionView.allowsMultipleSelection = YES;
    swipeOffset = diaryPhotosView.frame.size.height;
    [photoCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    photoFlowLayout.headerReferenceSize = CGSizeMake(photoCollectionView.frame.size.width, 44);
    [self.view addSubview:photoCollectionView];
    
    photoAlbumTable = [[UITableView alloc]initWithFrame:CGRectMake(-320, 408,320,self.view.frame.size.height-44) style:UITableViewStyleGrouped];
    photoAlbumTable.delegate = self;
    photoAlbumTable.dataSource = self;
    [photoAlbumTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    photoAlbumTable.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    [self.view addSubview:photoAlbumTable];
    
    scrollToBottom = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPhotoCollectionView) name:@"loadLibraySourceDone" object:nil];
    photoLoader = [[PhotoLoader alloc]initWithSourceType:kSourceTypePhoto];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSelection)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    faceDetectingActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    faceDetectingActivity.frame = self.view.frame;
    [self.view addSubview:faceDetectingActivity];
    
    faceDetectionEnabled = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (void)swipePhotoCollection:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
        sender.direction = UISwipeGestureRecognizerDirectionDown;
        [UIView animateWithDuration:0.5 animations:^{
            sender.view.frame = CGRectOffset(sender.view.frame, 0, -swipeOffset);
            photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 0, -swipeOffset);

        } completion:^(BOOL finished) {
            //
        }];
        
    }
    else if (sender.direction == UISwipeGestureRecognizerDirectionDown) {
        sender.direction = UISwipeGestureRecognizerDirectionUp;
        [UIView animateWithDuration:0.5 animations:^{
            sender.view.frame = CGRectOffset(sender.view.frame, 0, swipeOffset);
            photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 0, swipeOffset);
            
        } completion:^(BOOL finished) {
            //
        }];
    }
}

#pragma mark - Diary photo collection view relate
#pragma mark

- (void)processFaceDetection
{
    [self cellSizeArray];
    [cellImageArray removeAllObjects];
    // Process face detection
    for (int i = 0 ; i < [fullScreenImageArray count]; i++) {
        
        CGSize size = [sizeArray[i] CGSizeValue];
        
        UIImage *resizeImage = fullScreenImageArray[i];
        
        UIImage *cellImage;
        
        if (faceDetectionEnabled)
            cellImage = [resizeImage cropWithFaceDetect:size];
        else
            cellImage = [resizeImage cropWithoutFaceOutDetect:size];

        [cellImageArray addObject:cellImage];
        
        [self performSelectorOnMainThread:@selector(reloadDiaryPhotosView) withObject:nil waitUntilDone:YES];
    }
}

- (void)processFaceDetectionWithIndexPath:(NSIndexPath *)path
{
    CGSize size = [sizeArray[path.row] CGSizeValue];
    
    UIImage *fullScreenImage = fullScreenImageArray[path.row];
    
    UIImage *cellImage;
    
    if (faceDetectionEnabled)
        cellImage = [fullScreenImage cropWithFaceDetect:size];
    else
        cellImage = [fullScreenImage cropWithoutFaceOutDetect:size];
    
    cellImageArray[path.row] = cellImage;
        
    [self performSelectorOnMainThread:@selector(reloadCellWithIndexPath:) withObject:path waitUntilDone:YES];
}

- (void)reloadDiaryPhotosView
{
    [diaryPhotosView reloadData];
    [faceDetectingActivity stopAnimating];
}

- (void)reloadCellWithIndexPath:(NSIndexPath *)path
{
    [diaryPhotosView reloadItemsAtIndexPaths:@[path]];
}

- (void)deletePhoto {
    deleteDiaryPhotos = true;
    [diaryPhotosView reloadData];
}

- (void)cellSizeArray
{
    CGFloat sizeWidth = diaryPhotosView.frame.size.width-diaryCollectionViewInset.left-diaryCollectionViewInset.right;
    CGFloat sizeHeight = diaryPhotosView.frame.size.height-diaryCollectionViewInset.top-diaryCollectionViewInset.bottom;
    switch ([selectedPhotoOrderingInfo count]) {
        case 1:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, sizeHeight)]];
            break;
        case 2:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)]
                          ];
            break;
        case 3:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
                          ];
            break;
        case 4:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
                          ];
            break;
        case 5:
            //
            sizeArray = @[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                          [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
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
                [fullScreenImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [self processFaceDetection];
            }];
        }
        else {
            [diaryPhotosView reloadItemsAtIndexPaths:@[currentCellIndexPath]];
        }
    }
}

#pragma mark -DiaryPhotoViewDelegate

-(void)filteredImage:(UIImage *)image indexPath:(NSIndexPath *)path
{
    NSArray *imageInfo =  selectedPhotoOrderingInfo[path.row];
    
    // Replace image in selectedPhotoDict
    NSMutableDictionary *selectedPhotoDict = [selectedPhotoInfo objectForKey:imageInfo[1]];
    [selectedPhotoDict setObject:image forKey:imageInfo[0]];
    
    // Replace image in fullscreenimage array
    fullScreenImageArray[path.row] = image;

    [self processFaceDetectionWithIndexPath:path];
}

#pragma mark -Diary relate
- (void)doneSelection
{
    _diary = [[DiaryDataStore sharedStore]createItem];
    
    // Store image in the ImageStore with this key
    FileManager *fm = [[FileManager alloc]initWithKey:_diary.diaryKey];
    
    // Save raw image in local document directory
    for (int i=0;i < [selectedPhotoOrderingInfo count];i++) {
        NSArray *imageInfo = selectedPhotoOrderingInfo[i];
        NSMutableDictionary *selectedPhotoDict = [selectedPhotoInfo objectForKey:imageInfo[1]];
        UIImage *image = [selectedPhotoDict objectForKey:imageInfo[0]];
        [fm saveDiaryImage:image index:i];
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
    
    DiaryEntryViewController *entryViewController = [[DiaryEntryViewController alloc]init];
    entryViewController.diary = _diary;
    [self.navigationController pushViewController:entryViewController animated:YES];
}

-(void)cancelDiary
{
    if (_diary)
        [[DiaryDataStore sharedStore]removeItem:_diary];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Photo collection view relate
#pragma mark

- (void)setupPhotoCollectionView
{
    NSArray *sourceKeys = photoLoader.sourceDictionary.allKeys;
    
    // Set up dictionary to preserve image and index path and album name
    for (NSString *key in sourceKeys) {
        NSMutableDictionary *photoGroupDict = [[NSMutableDictionary alloc]init];
        [selectedPhotoInfo setValue:photoGroupDict forKey:key];
    }
    
    NSString *sourceKey = sourceKeys[1];
    assetGroupPropertyName = sourceKey;
    photoAssets = [photoLoader.sourceDictionary objectForKey:sourceKey];
    [photoCollectionView reloadData];
}

- (void)reloadPhotoCollectionView:(NSMutableArray *)selectedAlbum
{
    photoAssets = selectedAlbum;
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
//    // Retrieve the image orientation from the ALAsset
//    UIImageOrientation orientation = UIImageOrientationUp;
//    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
//    if (orientationValue != nil) {
//        orientation = [orientationValue intValue];
//    }
//    
//    UIImage* image = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]
//                                         scale:1 orientation:orientation];
    
    UIImage* image = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];

    // Put image selected photo dictionary
    NSMutableDictionary *selectedPhotoDict =  [selectedPhotoInfo objectForKey:assetGroupPropertyName];
    [selectedPhotoDict setObject:image forKey:indexPath];
    
    // Create info array for diary collection view
    NSArray *imageInfo = @[indexPath,assetGroupPropertyName];
    [selectedPhotoOrderingInfo addObject:imageInfo];

    // Resize the image
//    UIImage *resizedImage =  [image resizeImageToSize:CGSizeMake(640, 1136)];
    [fullScreenImageArray addObject:image];
    
    // Perform face detection and setup diary collection view
    [faceDetectingActivity startAnimating];
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
        cellPhoto.frame = CGRectMake(2, 2, cell.frame.size.width -4, cell.frame.size.height-4);
        [cell.contentView addSubview:cellPhoto];
        
        UIView* backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        backgroundView.backgroundColor = [UIColor blackColor];
        cell.backgroundView = backgroundView;
        
        UIView* selectedBGView = [[UIView alloc] initWithFrame:cell.bounds];
        selectedBGView.backgroundColor = [UIColor grayColor];
        cell.selectedBackgroundView = selectedBGView;

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
                [fullScreenImageArray removeObjectAtIndex:indexPath.row];
                
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
            photoViewController.indexPath = indexPath;
            photoViewController.delegate = self;
            [self.navigationController pushViewController:photoViewController animated:YES];
        }
        
    }
    
    // Photo collection view select
    else {
        [self selectedPhoto:indexPath];
//        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
//        cell.layer.borderColor = [[UIColor blueColor]CGColor];
//        cell.layer.borderWidth = 3.0f;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==1) {
        [self removePhotoWithIndexPath:indexPath];
//        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
//        cell.layer.borderColor = nil;
//        cell.layer.borderWidth = 0.0f;
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
            [fullScreenImageArray removeObjectAtIndex:index];

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
        CGFloat cellWidth = (collectionView.bounds.size.width-photoCollectionViewInset.right -photoCollectionViewInset.left -(3*photoMinimunLineSpace))/4;
        return CGSizeMake(cellWidth, cellWidth);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (collectionView.tag==0)
        return diaryCollectionViewInset;
    else
        return photoCollectionViewInset;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (collectionView.tag==0)
        return diaryMinimunLineSpace;
    else
        return photoMinimunLineSpace;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if (collectionView.tag==0)
        return diaryMinimunCellSpace;
    else
        return photoMinimunCellSpace;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    if (kind ==UICollectionElementKindSectionHeader && collectionView.tag == 1) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        //headerView.backgroundColor = [UIColor redColor];
        UINavigationBar *navBar = [[UINavigationBar alloc]initWithFrame:headerView.frame];
        UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:assetGroupPropertyName];
        navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(showTable)];
        navItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(disableFaceDetection)];
        [navBar setItems:@[navItem]];
        [headerView addSubview:navBar];
        return headerView;
    }
    return reusableview;
}

- (void)showTable
{
    NSLog(@"show table");
    [photoAlbumTable reloadData];
    photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 320, 0);

    photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 320, 0);
}

- (void)disableFaceDetection
{
    if (faceDetectionEnabled) {
        faceDetectionEnabled = NO;
        NSLog(@"face detection disabled");

    }
    else {
        faceDetectionEnabled = YES;
        NSLog(@"face detection enabled");


    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSArray *souceKeys = photoLoader.sourceDictionary.allKeys;
    NSString *key = souceKeys[indexPath.row];
    cell.textLabel.text = key;
    
    NSMutableArray *photoAlbum = [[photoLoader sourceDictionary] objectForKey:key];
    ALAsset *asset = [photoAlbum lastObject];
    cell.imageView.image = [UIImage imageWithCGImage: asset.thumbnail];

    //cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld",[photoAlbum count]];
    //NSLog(@"%@",[NSString stringWithFormat:@"%ld",[photoAlbum count]]);
    return cell;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [photoLoader.sourceDictionary count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *souceKeys = photoLoader.sourceDictionary.allKeys;
    NSString *key = souceKeys[indexPath.row];
    NSMutableArray *photoAlbum = [[photoLoader sourceDictionary] objectForKey:key];
    [self reloadPhotoCollectionView:photoAlbum];
    tableView.frame = CGRectOffset(tableView.frame, -320, 0);
    photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, -320, 0);

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - Memory Warning
#pragma mark

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end