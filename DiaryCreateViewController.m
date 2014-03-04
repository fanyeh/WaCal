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
#import "DiaryPhotoCell.h"
#import "DiaryPhotoViewController.h"
#import "DiaryEntryViewController.h"
#import "AlbumPhotoCell.h"
#import <MediaPlayer/MediaPlayer.h>

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
#define GrayUIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:0.5]

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
    UINavigationItem *navItem ;
    UINavigationBar *navBar ;
    CGFloat photoCollectionExpandHeight;
    CGFloat photoCollectionShrinkHeight;
    NSMutableArray *imageMeta;

    BOOL showAlbumTable;
    
    UIActivityIndicatorView *faceDetectingActivity;
    MPMoviePlayerViewController *videoPlayer;
    UIAlertView *preparingAlertView;
    UIView *scroller;
    
    NSIndexPath *videoIndexPath;
    
    MediaType selectedMediaType;
    
    UIView *videoView;
    UIImageView *videoImageView;
}

@property (weak, nonatomic) IBOutlet UIView *noPhotoView;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;

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
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationItem.title = @"New Diary";
    
    videoView = [[UIView alloc]initWithFrame:CGRectMake(2, 46, 316, 316)];
    videoImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 316, 316)];
    [self.view addSubview:videoView];
    [videoView addSubview:videoImageView];
    UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playMovie)];
    [videoView addGestureRecognizer:videoTap];
    
    // Set up diary photo collection view
    diaryCollectionViewInset = UIEdgeInsetsMake(2, 2, 2, 2);
    diaryMinimunCellSpace = 2.0;
    diaryMinimunLineSpace = 2.0;

    UICollectionViewFlowLayout *diaryFlowLayout = [[UICollectionViewFlowLayout alloc]init];
    diaryPhotosView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 44, 320, 320) collectionViewLayout:diaryFlowLayout];
    diaryPhotosView.delegate = self;
    diaryPhotosView.dataSource = self;
    diaryPhotosView.tag = 0;
    diaryPhotosView.allowsMultipleSelection = NO;
    diaryPhotosView.backgroundColor = [UIColor whiteColor];
    [diaryPhotosView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"DiaryPhotoCell"];
    selectedPhotoInfo = [[NSMutableDictionary alloc]init];
    fullScreenImageArray = [[NSMutableArray alloc]init];
    cellImageArray = [[NSMutableArray alloc]init];
    selectedPhotoOrderingInfo = [[NSMutableArray alloc]init];
    [self.view addSubview:diaryPhotosView];

    // Scroll control for photo collection view
    scroller = [[UIView alloc]initWithFrame:CGRectMake(0, 364 , 320, 54)];
    scroller.backgroundColor = [UIColor blackColor];
    UISwipeGestureRecognizer *swipGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipePhotoCollection:)];
    swipGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [scroller addGestureRecognizer:swipGesture];
    swipeOffset = diaryPhotosView.frame.size.height;
    [self.view addSubview:scroller];
    
    // Scroller for photo collection
    UILabel *scrollerBar = [[UILabel alloc]initWithFrame:CGRectMake(scroller.center.x - 20, 4, 40, 6)];
    scrollerBar.backgroundColor = [UIColor whiteColor];
    scrollerBar.layer.cornerRadius = 3;
    [scroller addSubview:scrollerBar];
    navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 10 , 320, 44)];
    navBar.backgroundColor = [UIColor clearColor];
    navBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    navItem = [[UINavigationItem alloc]init];
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"◀︎" style:UIBarButtonItemStyleBordered target:self action:@selector(showTable)];
    navItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Photo 0/5" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [navBar setItems:@[navItem]];
    [scroller addSubview:navBar];

    // Set up photo album collection view
    photoCollectionViewInset = UIEdgeInsetsMake(2, 2, 2, 2);
    photoMinimunCellSpace = 1;
    photoMinimunLineSpace = 1;

    photoCollectionExpandHeight = self.view.frame.size.height - 44 - scroller.frame.size.height;
    photoCollectionShrinkHeight = self.view.frame.size.height - 44 - diaryPhotosView.frame.size.height - scroller.frame.size.height;
    
    UICollectionViewFlowLayout *photoFlowLayout = [[UICollectionViewFlowLayout alloc]init];
    photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 418, 320, photoCollectionExpandHeight)
                                            collectionViewLayout:photoFlowLayout];
    photoCollectionView.delegate = self;
    photoCollectionView.dataSource = self;
    photoCollectionView.tag = 1;
    photoCollectionView.backgroundColor = [UIColor whiteColor];

    photoCollectionView.showsVerticalScrollIndicator = NO;
    [photoCollectionView registerClass:[AlbumPhotoCell class] forCellWithReuseIdentifier:@"AlbumPhotoCell"];
    photoCollectionView.allowsMultipleSelection = YES;
    [self.view addSubview:photoCollectionView];
    
    imageMeta = [[NSMutableArray alloc]init];
    
    // Table view for change photo album
    photoAlbumTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 418, 320, photoCollectionExpandHeight)
                                                  style:UITableViewStyleGrouped];
    photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, -320, 0);
    photoAlbumTable.delegate = self;
    photoAlbumTable.dataSource = self;
    [photoAlbumTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    photoAlbumTable.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    photoAlbumTable.backgroundColor = [UIColor blackColor];
    [self.view addSubview:photoAlbumTable];
    showAlbumTable = NO;

    scrollToBottom = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPhotoCollectionView) name:@"loadLibraySourceDone" object:nil];
    photoLoader = [[PhotoLoader alloc]initWithSourceType:kSourceTypeAll];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSelection)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Face detection
    faceDetectingActivity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    faceDetectingActivity.frame = self.view.frame;
    [self.view addSubview:faceDetectingActivity];
    
    UIPanGestureRecognizer *faceDetectPan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panFaceDetectView:)];
    [_faceImageView addGestureRecognizer:faceDetectPan];
    UITapGestureRecognizer *faceDetectTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapFaceDetectView:)];
    [_faceImageView addGestureRecognizer:faceDetectTap];
    _faceImageView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.300];
    _faceImageView.layer.borderColor = [[UIColor grayColor]CGColor];
    _faceImageView.layer.borderWidth = 2.0f;
    _faceImageView.layer.cornerRadius = 5.0f;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"FaceDetection"]) {
        _faceImageView.image = [UIImage imageNamed:@"face_yellow.png"];
    } else {
        _faceImageView.image = [UIImage imageNamed:@"face_white.png"];
    }
    
    [self.view bringSubviewToFront:_faceImageView];
    [self.view bringSubviewToFront:_noPhotoView];
    [self.view bringSubviewToFront:photoAlbumTable];
    [self.view bringSubviewToFront:photoCollectionView];
    [self.view bringSubviewToFront:scroller];
}

-(void)panFaceDetectView:(UIPanGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self.view];
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint center = sender.view.center;
        center.x = point.x;
        center.y = point.y;
        sender.view.center = center;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        CGRect frame = sender.view.frame;
        if (frame.origin.x < diaryPhotosView.frame.origin.x)
            frame.origin.x = diaryPhotosView.frame.origin.x+5;
        if (frame.origin.y < diaryPhotosView.frame.origin.y)
            frame.origin.y = diaryPhotosView.frame.origin.y+5;
        if (frame.origin.x+frame.size.width > diaryPhotosView.frame.origin.x+diaryPhotosView.frame.size.width)
            frame.origin.x = diaryPhotosView.frame.origin.x+diaryPhotosView.frame.size.width-5-frame.size.width;
        if (frame.origin.y+frame.size.height > diaryPhotosView.frame.origin.y+diaryPhotosView.frame.size.height)
            frame.origin.y = diaryPhotosView.frame.origin.y+diaryPhotosView.frame.size.height-5-frame.size.height;
        [UIView animateWithDuration:0.5f animations:^{
            sender.view.frame = frame;
        }];
    }
}

-(void)tapFaceDetectView:(UITapGestureRecognizer *)sender
{
    BOOL faceDetection = [[NSUserDefaults standardUserDefaults] boolForKey:@"FaceDetection"];
    if (faceDetection) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FaceDetection"];
        _faceImageView.image = [UIImage imageNamed:@"face_white.png"];

    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FaceDetection"];
        _faceImageView.image = [UIImage imageNamed:@"face_yellow.png"];
    }
    
    [self processFaceDetection];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
    photoAlbumTable.hidden = YES;

}

-(void)viewDidAppear:(BOOL)animated
{
    photoAlbumTable.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
    photoAlbumTable.hidden = YES;
}

- (void)swipePhotoCollection:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionUp) {
        sender.direction = UISwipeGestureRecognizerDirectionDown;
        photoCollectionView.frame = CGRectMake(photoCollectionView.frame.origin.x,
                                               photoCollectionView.frame.origin.y,
                                               320,
                                               photoCollectionExpandHeight);
        
        
        photoAlbumTable.frame = CGRectMake(photoAlbumTable.frame.origin.x,
                                               photoAlbumTable.frame.origin.y,
                                               320,
                                               photoCollectionExpandHeight);
        [UIView animateWithDuration:0.5 animations:^{
            if ([cellImageArray count]>0) {
                sender.view.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.60];
            }
            sender.view.frame = CGRectOffset(sender.view.frame, 0, -swipeOffset);
            photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 0, -swipeOffset);

            photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 0, -swipeOffset);

        } completion:^(BOOL finished) {

        }];
        
    }
    else if (sender.direction == UISwipeGestureRecognizerDirectionDown) {

        sender.direction = UISwipeGestureRecognizerDirectionUp;
        [UIView animateWithDuration:0.5 animations:^{
            sender.view.backgroundColor = [UIColor blackColor];
            sender.view.frame = CGRectOffset(sender.view.frame, 0, swipeOffset);
            photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 0, swipeOffset);
            photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 0, swipeOffset);

            
        } completion:^(BOOL finished) {

            photoCollectionView.frame = CGRectMake(photoCollectionView.frame.origin.x,
                                                   photoCollectionView.frame.origin.y,
                                                   320,
                                                   photoCollectionShrinkHeight);
            
            photoAlbumTable.frame = CGRectMake(photoAlbumTable.frame.origin.x,
                                               photoAlbumTable.frame.origin.y,
                                               320,
                                               photoCollectionExpandHeight);

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
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"FaceDetection"])
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
    
    if ([[NSUserDefaults standardUserDefaults]boolForKey:@"FaceDetection"])
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
    DiaryEntryViewController *entryViewController = [[DiaryEntryViewController alloc]init];
    entryViewController.selectedMediaType = selectedMediaType;

    if (selectedMediaType == kMediaTypePhoto) {
        // Create Image from collection view
        UIGraphicsBeginImageContextWithOptions(diaryPhotosView.bounds.size, YES, [UIScreen mainScreen].scale);
        [diaryPhotosView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *collectionViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        entryViewController.diaryImage = collectionViewImage;
        entryViewController.imageMeta = imageMeta;
    } else {
        ALAsset *videoAsset = [photoAssets objectAtIndex:videoIndexPath.row];
        entryViewController.asset = videoAsset;
    }
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
    navItem.title = assetGroupPropertyName;
    [photoCollectionView reloadData];
}

- (void)reloadPhotoCollectionView:(NSMutableArray *)selectedAlbum
{
    photoAssets = selectedAlbum;
    [photoCollectionView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (int i = 0; i< [selectedPhotoOrderingInfo count];i++) {
            NSArray *imageInfo = [selectedPhotoOrderingInfo objectAtIndex:i];
            if ([assetGroupPropertyName isEqualToString:imageInfo[1]]) {
                NSIndexPath *path = imageInfo[0];
                NSInteger selectNumber = i + 1;
                [photoCollectionView selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
                AlbumPhotoCell *cell = (AlbumPhotoCell *)[photoCollectionView cellForItemAtIndexPath:path];
                cell.selectNumber.text = [NSString stringWithFormat:@"%ld", selectNumber];

            }
        }
    });
}

- (void)selectedPhoto:(NSIndexPath *)indexPath
{
    _noPhotoView.hidden = YES;
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
    
    // Create info array for diary collection view
    NSArray *imageInfo = @[indexPath,assetGroupPropertyName];
    [selectedPhotoOrderingInfo addObject:imageInfo];

    // Save image meta data
    [imageMeta addObject:asset.defaultRepresentation.metadata];
    
    // Resize the image
    [fullScreenImageArray addObject:image];
    navItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Photo %ld/5",[fullScreenImageArray count]];
    
    AlbumPhotoCell *cell = (AlbumPhotoCell *)[photoCollectionView cellForItemAtIndexPath:indexPath];
    cell.selectNumber.text = [NSString stringWithFormat:@"%ld",[fullScreenImageArray count]];
    
    // Perform face detection and setup diary collection view
    [faceDetectingActivity startAnimating];
    [self performSelectorInBackground:@selector(processFaceDetection) withObject:nil];
    
}

-(void)cancelPhotoSelection
{
    
    for (int i = 0; i < [selectedPhotoOrderingInfo count] ; i++) {
        NSArray *n = [selectedPhotoOrderingInfo objectAtIndex:i];
        [photoCollectionView deselectItemAtIndexPath:n[0] animated:YES];
    }
    
    [selectedPhotoOrderingInfo removeAllObjects];
    [fullScreenImageArray removeAllObjects];
    [cellImageArray removeAllObjects];
    [diaryPhotosView reloadData];
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
        [UIView animateWithDuration:0.5f animations:^{
            cell.photoView.frame = cell.contentView.bounds;
        }];

        if ([cellImageArray count] > 0)
            cell.photoView.image = cellImageArray[indexPath.row];
        
        // Add gesture to each cell
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self
                                                                                               action:@selector(enlargCell:)];
        [cell addGestureRecognizer:longPress];
        return cell;
        
    } else {
        AlbumPhotoCell *cell = (AlbumPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumPhotoCell" forIndexPath:indexPath];
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        cell.asset = asset;
        
        cell.cellImageView.image = [UIImage imageWithCGImage: asset.thumbnail];
        for (int i = 0; i < [selectedPhotoOrderingInfo count] ; i++) {
            NSArray *n = [selectedPhotoOrderingInfo objectAtIndex:i];
            if(indexPath == n[0])
                cell.selectNumber.text = [NSString stringWithFormat:@"%d",i+1];
        }
        
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
            [cell formatVideoInterval:[asset valueForProperty:ALAssetPropertyDuration]];
        } else {
            cell.videoTimeLabel.hidden = YES;
        }
        
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
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
            if ([fullScreenImageArray count] > 0) {
                [self cancelPhotoSelection];
            }
            if (videoIndexPath)
                [photoCollectionView deselectItemAtIndexPath:videoIndexPath animated:YES];

            navItem.rightBarButtonItem.title = @"Video 1/1";
            videoIndexPath = indexPath;
            selectedMediaType = kMediaTypeVideo;
            UIImage *cellImage = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
            videoImageView.image = [cellImage cropWithFaceDetect:videoImageView.frame.size];
            videoView.hidden = NO;
            [self.view bringSubviewToFront:videoView];
            [self.view bringSubviewToFront:scroller];
            [self.view bringSubviewToFront:photoAlbumTable];
            [self.view bringSubviewToFront:photoCollectionView];
            
        } else {
            [self cancelMPMoviePlayer];
            videoIndexPath = nil;
            selectedMediaType = kMediaTypePhoto;
            [self selectedPhoto:indexPath];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==1) {
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
            [self cancelMPMoviePlayer];
            navItem.rightBarButtonItem.title = @"Video 0/1";
        } else {
            [self removePhotoWithIndexPath:indexPath];
        }
    }
}

- (void)cancelMPMoviePlayer
{
    [photoCollectionView deselectItemAtIndexPath:videoIndexPath animated:YES];
    diaryPhotosView.hidden = NO;
    [cellImageArray removeAllObjects];
    videoView.hidden = YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        if ([fullScreenImageArray count]>4) {
            UIAlertView *fullAlert = [[UIAlertView alloc]initWithTitle:nil
                                                               message:@"You may select up to 5 photos"
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil, nil];
            [fullAlert show];
            return NO;
        } else
            return YES;

    } else {
        return YES;
    }
}

#pragma mark -Remove Photo

- (void)removePhotoWithIndexPath:(NSIndexPath *)path
{
    for (NSArray *imageInfo in selectedPhotoOrderingInfo) {
        // ImageInfo[0] = indexpath
        // ImageInfo[1] = assset group name
        if (imageInfo[0] == path) {
            
            // Remove image from resize image array
            NSUInteger index = [selectedPhotoOrderingInfo indexOfObject:imageInfo];
            [imageMeta removeObjectAtIndex:index];
            [fullScreenImageArray removeObjectAtIndex:index];
            navItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Photo %ld/5",[fullScreenImageArray count]];

            // Remove image info from ordering info
            [selectedPhotoOrderingInfo removeObject:imageInfo];
            
            if([selectedPhotoOrderingInfo count]==0)
                _noPhotoView.hidden = NO;
            
            for (int i = 0; i < [selectedPhotoOrderingInfo count] ; i++) {
                NSArray *n = [selectedPhotoOrderingInfo objectAtIndex:i];
                AlbumPhotoCell *cell = (AlbumPhotoCell *)[photoCollectionView cellForItemAtIndexPath:n[0]];
                cell.selectNumber.text = [NSString stringWithFormat:@"%d",i+1];
            }
            
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

- (void)showTable
{
    [photoAlbumTable reloadData];

    if (!showAlbumTable) {
        photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 320, 0);
        photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 320, 0);
        showAlbumTable = YES;
    } else {
        photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, -320, 0);
        photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, -320, 0);
        showAlbumTable = NO;
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
    cell.backgroundColor = [UIColor colorWithWhite:0.298 alpha:1.000];

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
    assetGroupPropertyName = key;
    navItem.title = assetGroupPropertyName;
    NSMutableArray *photoAlbum = [[photoLoader sourceDictionary] objectForKey:key];
    [self reloadPhotoCollectionView:photoAlbum];
    tableView.frame = CGRectOffset(tableView.frame, -320, 0);
    photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, -320, 0);
    showAlbumTable = NO;

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

#pragma mark - Movie player
#pragma mark

-(void) playMovie
{
    ALAsset *videoAsset = [photoAssets objectAtIndex:videoIndexPath.row];
    diaryPhotosView.hidden = YES;
    videoPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL: videoAsset.defaultRepresentation.url];
    [videoPlayer.moviePlayer setContentURL:videoAsset.defaultRepresentation.url];
    
    
    [videoPlayer.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:1.0]] timeOption:MPMovieTimeOptionExact];
    // Setup the player
    videoPlayer.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    videoPlayer.moviePlayer.shouldAutoplay = NO;
    
    // Add Movie Player to parent's view
    //    [videoPlayer.view setFrame:CGRectMake(2, 46, 316, 320)];
    videoPlayer.view.layer.borderColor = [[UIColor whiteColor]CGColor];
    videoPlayer.view.layer.borderWidth = 2.0f;
    [videoPlayer.moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
    
    videoPlayer.moviePlayer.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self presentMoviePlayerViewControllerAnimated:videoPlayer];
    
    [self.view addSubview:videoPlayer.view];
    [self.view bringSubviewToFront:photoAlbumTable];
    [self.view bringSubviewToFront:photoCollectionView];
    [self.view bringSubviewToFront:scroller];
    
    // Register for the playback finished notification
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePreloadDidFinish:)
                                                   name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                 object: videoPlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePlayBackDidFinish:)
                                                   name: MPMoviePlayerPlaybackDidFinishNotification
                                                 object: videoPlayer.moviePlayer];
    [videoPlayer.moviePlayer prepareToPlay];
    [videoPlayer.moviePlayer pause];
    [self launchPreparingAlertViewAlert];
}

#pragma mark Media Playback Notification Methods

- (void) moviePreloadDidFinish:(NSNotification*)notification
{
    [self dismissPreparingAlert];
}

-(void) moviePlayBackDidFinish: (NSNotification*) aNotification
{
    MPMoviePlayerController* moviePlayer=[aNotification object];
    
    // UnRegister for the playback finished notification
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object: moviePlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMoviePlayerPlaybackDidFinishNotification
                                                  object: moviePlayer];
    
    // Remove from the parent's view
    [moviePlayer.view removeFromSuperview];
    
    // Stop before release to workaround iOS's bug
    [moviePlayer stop];
}

#pragma mark -
#pragma mark preparingAlertView Methods

- (void) launchPreparingAlertViewAlert {
	// Launch Downloading Alert
	if(preparingAlertView!=nil)	// Don't need to launch again
		return;
	
	preparingAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Movie Preparing..."
                                                   delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
	
	UIActivityIndicatorView *waitView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	waitView.frame = CGRectMake(120, 50, 40, 40);
	[waitView startAnimating];
	
	[preparingAlertView addSubview:waitView];
	[preparingAlertView show];
}

- (void) dismissPreparingAlert {
	if(preparingAlertView!=nil)
	{
		// Dismiss Downloading alert
		[preparingAlertView dismissWithClickedButtonIndex:0 animated:YES];//important
		preparingAlertView=nil;
	}
}

@end