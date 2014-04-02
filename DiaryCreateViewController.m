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
#import "PhotoAlbumTableCell.h"

static int deleteLabelSize = 30;

@interface DiaryCreateViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,filterImageDelegate,UITableViewDataSource,UITableViewDelegate>
{
    // Diary photo collection view property
    UIEdgeInsets diaryCollectionViewInset;
    CGFloat diaryMinimunCellSpace;
    CGFloat diaryMinimunLineSpace;
    
    UICollectionView *diaryPhotosView; // Tag 0
    CGPoint _priorPoint;
    NSMutableArray *sizeArray;
//    NSMutableDictionary *selectedPhotoInfo;
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
    
    MPMoviePlayerViewController *videoPlayer;
    UIAlertView *preparingAlertView;
    UIView *scroller;
    
    NSIndexPath *videoIndexPath;
    MediaType selectedMediaType;
    UIView *videoView;
    UIImageView *videoImageView;
    UIBarButtonItem *nextButton;
    UILabel *videoDeleteLabel;
    
    DiaryPhotoCell *touchedCell;
    UILabel *frameView;
}

@property (weak, nonatomic) IBOutlet UIView *noPhotoView;
@property (weak, nonatomic) IBOutlet UIImageView *faceImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *faceDetectingActivity;


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
    self.navigationItem.title = @"Photos";
    
    videoView = [[UIView alloc]initWithFrame:CGRectMake(2, 46, 316, 316)];
    UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playMovie)];
    [videoView addGestureRecognizer:videoTap];
    
    videoImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 316, 316)];
    videoImageView.userInteractionEnabled  = YES;
    UILongPressGestureRecognizer *showDeleteVideo = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showDeleteVideoButton:)];
    [videoImageView addGestureRecognizer:showDeleteVideo];
    
    videoDeleteLabel = [[UILabel alloc]initWithFrame:CGRectMake(videoView.frame.size.width-deleteLabelSize-3, 3, deleteLabelSize, deleteLabelSize)];
    videoDeleteLabel.backgroundColor = [UIColor redColor];
    videoDeleteLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    videoDeleteLabel.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    videoDeleteLabel.text = @"X";
    videoDeleteLabel.textColor = [UIColor whiteColor];
    videoDeleteLabel.textAlignment = NSTextAlignmentCenter;
    videoDeleteLabel.layer.borderColor = [[UIColor whiteColor]CGColor];
    videoDeleteLabel.layer.borderWidth = 2.0f;
    videoDeleteLabel.layer.cornerRadius = videoDeleteLabel.frame.size.width/2;
    videoDeleteLabel.hidden = YES;
    videoDeleteLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *videoDeleteTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelMPMoviePlayer)];
    [videoDeleteLabel addGestureRecognizer:videoDeleteTap];
    
    [videoView addSubview:videoImageView];
    [videoView addSubview:videoDeleteLabel];
    [self.view addSubview:videoView];
    
    UIView *videoPlayView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 88, 88)];
    videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
    videoPlayView.layer.borderWidth = 3.0f;
    videoPlayView.layer.cornerRadius = videoPlayView.frame.size.width/2;
    videoPlayView.center = videoImageView.center;
    videoPlayView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
    [videoImageView addSubview:videoPlayView];
    
    UIImageView *playButtonView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
    playButtonView.image = [UIImage imageNamed:@"playButton.png"];
    playButtonView.center = videoImageView.center;
    playButtonView.frame = CGRectOffset(playButtonView.frame, 5, 0);
    [videoImageView addSubview:playButtonView];
    
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
    [diaryPhotosView registerClass:[DiaryPhotoCell class] forCellWithReuseIdentifier:@"DiaryPhotoCell"];
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
    
    // Navigation bar on scroller
    navBar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 10 , 320, 44)];
    
    [navBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundColor:[UIColor clearColor]];
    navBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    navItem = [[UINavigationItem alloc]init];
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"◀︎" style:UIBarButtonItemStyleBordered target:self action:@selector(showTable)];
    navItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"0/5" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [navBar setItems:@[navItem]];
    [scroller addSubview:navBar];

    // Set up photo album collection view
    photoCollectionViewInset = UIEdgeInsetsMake(2, 2, 2, 2);
    photoMinimunCellSpace = 1;
    photoMinimunLineSpace = 1;

    CGSize screenSize = [[UIScreen mainScreen]bounds].size;
    photoCollectionExpandHeight = screenSize.height - 44 - scroller.frame.size.height;
    photoCollectionShrinkHeight = screenSize.height - 44 - diaryPhotosView.frame.size.height - scroller.frame.size.height;
    
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
    photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 320, 0);
    photoAlbumTable.delegate = self;
    photoAlbumTable.dataSource = self;
    photoAlbumTable.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    photoAlbumTable.backgroundColor = [UIColor blackColor];
    photoAlbumTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    photoAlbumTable.allowsMultipleSelection = NO;
    photoAlbumTable.allowsSelection = YES;
    [photoAlbumTable registerNib:[UINib nibWithNibName:@"PhotoAlbumTableCell" bundle:nil]
         forCellReuseIdentifier:@"PhotoAlbumTableCell"];
    photoAlbumTable.tintColor = MainColor;
    [self.view addSubview:photoAlbumTable];
    showAlbumTable = NO;

    scrollToBottom = NO;
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupPhotoCollectionView) name:@"loadLibraySourceDone" object:nil];
    photoLoader = [[PhotoLoader alloc]initWithSourceType:kSourceTypeAll];
    photoAssets = [[NSMutableArray alloc]init];
    
    nextButton = [[UIBarButtonItem alloc]initWithTitle:@"Words" style:UIBarButtonItemStylePlain target:self action:@selector(doneSelection)];
    
    UIPanGestureRecognizer *faceDetectPan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panFaceDetectView:)];
    [_faceImageView addGestureRecognizer:faceDetectPan];
    UITapGestureRecognizer *faceDetectTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapFaceDetectView:)];
    [_faceImageView addGestureRecognizer:faceDetectTap];
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
    [self.view bringSubviewToFront:_faceDetectingActivity];

}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
//    photoAlbumTable.hidden = YES;
    diaryPhotosView.backgroundColor = [UIColor clearColor];
}

-(void)viewDidAppear:(BOOL)animated
{
//    photoAlbumTable.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
//    photoAlbumTable.hidden = YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Diary photo collection view relate
#pragma mark

#pragma mark -Face Detection

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

- (void)processFaceDetection
{
    [_faceDetectingActivity startAnimating];
    [self cellSizeArray];
    [cellImageArray removeAllObjects];
    // Process face detection
    for (int i = 0 ; i < [fullScreenImageArray count]; i++) {
        
        CGSize size = [sizeArray[i] CGSizeValue];
        
        UIImage *fullscreenImage;

        if ([fullScreenImageArray[i] isKindOfClass:[ALAsset class]]) {
            ALAsset *asset = fullScreenImageArray[i];
            fullscreenImage = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
        } else
            fullscreenImage = fullScreenImageArray[i];
        
        UIImage *cellImage;
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"FaceDetection"])
            cellImage = [[fullscreenImage cropWithFaceDetect:size] resizeImageToSize:size];
        else
            cellImage = [[fullscreenImage cropWithoutFaceOutDetect:size] resizeImageToSize:size];

        [cellImageArray addObject:cellImage];
    }
    
    [diaryPhotosView performBatchUpdates:^{
        [diaryPhotosView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:^(BOOL finished) {
        [_faceDetectingActivity stopAnimating];
    }];
}

- (void)processFaceDetectionWithIndexPath:(NSArray *)paths
{
    [_faceDetectingActivity startAnimating];
    for (NSIndexPath *path in paths) {
        CGSize size = [sizeArray[path.row] CGSizeValue];
        
        UIImage *fullScreenImage;
        
        if ([fullScreenImageArray[path.row] isKindOfClass:[ALAsset class]]) {
            ALAsset *asset = fullScreenImageArray[path.row];
            fullScreenImage = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
        } else
            fullScreenImage = fullScreenImageArray[path.row];
        
        UIImage *cellImage;
        
        if ([[NSUserDefaults standardUserDefaults]boolForKey:@"FaceDetection"])
            cellImage = [[fullScreenImage cropWithFaceDetect:size]resizeImageToSize:size];
        else
            cellImage = [[fullScreenImage cropWithoutFaceOutDetect:size]resizeImageToSize:size];
        
        cellImageArray[path.row] = cellImage;
    }
        [diaryPhotosView performBatchUpdates:^{
            [diaryPhotosView reloadItemsAtIndexPaths:paths];
        } completion:^(BOOL finished) {
            [_faceDetectingActivity stopAnimating];

        }];
}

#pragma mark -User Actions

- (void)cellSizeArray
{
    CGFloat sizeWidth = diaryPhotosView.frame.size.width-diaryCollectionViewInset.left-diaryCollectionViewInset.right;
    CGFloat sizeHeight = diaryPhotosView.frame.size.height-diaryCollectionViewInset.top-diaryCollectionViewInset.bottom;
    switch ([selectedPhotoOrderingInfo count]) {
        case 1:
            //
            sizeArray = [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, sizeHeight)]]];
            break;
        case 2:
            //
            sizeArray = [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)]
                                                               ]];
            break;
        case 3:
            //
            sizeArray = [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
                                                               ]];
            break;
        case 4:
            //
            sizeArray = [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
                                                               ]];
            break;
        case 5:
            //
            sizeArray =[[NSMutableArray alloc]initWithArray: @[[NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace*2)/3, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)],
                                                               [NSValue valueWithCGSize:CGSizeMake((sizeWidth-diaryMinimunCellSpace)/2, (sizeHeight-diaryMinimunLineSpace)/2)]
                                                               ]];
            break;
        default:
            break;
    }
}

-(void)hidePhoto
{
    _noPhotoView.hidden = YES;
    diaryPhotosView.hidden = YES;
    _faceImageView.hidden = YES;
}

-(void)showPhoto
{
    diaryPhotosView.hidden = NO;
    _faceImageView.hidden = NO;
}


-(void)hideVideo
{
    _noPhotoView.hidden = YES;
    videoView.hidden = YES;
}

-(void)showVideo
{
    videoView.hidden = NO;
}

- (void)movePhoto:(UIPanGestureRecognizer *)sender
{
    DiaryPhotoCell *cell = (DiaryPhotoCell *)sender.view;
    
    // Shrink cell when it moved
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        _noPhotoView.hidden = YES;
        CGRect frame = [cell convertRect:cell.contentView.frame toView:self.view];
        frameView = [[UILabel alloc]initWithFrame:frame];
        frameView.layer.borderColor = [MainColor CGColor];
        frameView.layer.borderWidth = 2.0f;
        NSArray *imageInfo = [selectedPhotoOrderingInfo objectAtIndex:[diaryPhotosView indexPathForCell:cell].row];
        frameView.text = imageInfo[2];
        frameView.textColor = MainColor;
        frameView.textAlignment = NSTextAlignmentCenter;
        frameView.font = [UIFont fontWithName:@"Helvetica" size:30];
        [self.view addSubview:frameView];
        [self.view bringSubviewToFront:diaryPhotosView];
        [diaryPhotosView bringSubviewToFront:sender.view];
        [self.view bringSubviewToFront:_faceImageView];
        [self.view bringSubviewToFront:_faceDetectingActivity];
        [UIView animateWithDuration:0.3 animations:^{
            cell.transform = CGAffineTransformScale(cell.transform, 0.6, 0.6);
            cell.center = [sender locationInView:sender.view.superview];
        }];
        
        cell.deleteBadger.hidden = YES;
    }
    
    // Pan the cell
//    CGPoint point = [sender locationInView:sender.view.superview];
    CGPoint point = [sender translationInView:self.view];
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint center = sender.view.center;
        center.x += point.x - _priorPoint.x;
        center.y += point.y - _priorPoint.y;
        sender.view.center = center;
        
        NSIndexPath *touchedCellPath = [diaryPhotosView indexPathForItemAtPoint:CGPointMake(sender.view.center.x, sender.view.center.y)];
        NSIndexPath *currentCellIndexPath = [diaryPhotosView indexPathForCell:cell];
        
        if ((touchedCellPath != currentCellIndexPath) && (touchedCellPath != NULL)) {
            if (touchedCell) {
                [touchedCell showHighlight:NO];
            }
            touchedCell = (DiaryPhotoCell *)[diaryPhotosView cellForItemAtIndexPath:touchedCellPath];
            [touchedCell showHighlight:YES];

        } else {
            if (touchedCell) {
                [touchedCell showHighlight:NO];
            }
        }
    }
    _priorPoint = point;
    
    // Resize cell back when state ended or cancelled
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)
    {
        [frameView removeFromSuperview];
        [_faceDetectingActivity startAnimating];

        NSIndexPath *touchedCellPath = [diaryPhotosView indexPathForItemAtPoint:CGPointMake(sender.view.center.x, sender.view.center.y)];
        NSIndexPath *currentCellIndexPath = [diaryPhotosView indexPathForCell:cell];
        
        if ((touchedCellPath != currentCellIndexPath) && (touchedCellPath != NULL)) {
            touchedCell = (DiaryPhotoCell *)[diaryPhotosView cellForItemAtIndexPath:touchedCellPath];
            [touchedCell showHighlight:NO];
            touchedCell.deleteBadger.hidden = YES;
            
//            if ([sizeArray[currentCellIndexPath.row]isEqualToValue:sizeArray[touchedCellPath.row]])

            if (![sizeArray[currentCellIndexPath.row]isEqualToValue:sizeArray[touchedCellPath.row]]) {
                [selectedPhotoOrderingInfo exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [fullScreenImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                [self processFaceDetectionWithIndexPath:@[currentCellIndexPath,touchedCellPath]];
            }
            else {
                [diaryPhotosView performBatchUpdates:^{
                    [diaryPhotosView moveItemAtIndexPath:currentCellIndexPath toIndexPath:touchedCellPath];
                    [diaryPhotosView moveItemAtIndexPath:touchedCellPath toIndexPath:currentCellIndexPath];
                } completion:^(BOOL finished) {
                    [selectedPhotoOrderingInfo exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                    [fullScreenImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                    [cellImageArray exchangeObjectAtIndex:currentCellIndexPath.row withObjectAtIndex:touchedCellPath.row];
                }];
                [_faceDetectingActivity stopAnimating];
            }

        } else {
            [UIView animateWithDuration:0.0 animations:^{
                [diaryPhotosView reloadItemsAtIndexPaths:@[currentCellIndexPath]];
            }];
            [_faceDetectingActivity stopAnimating];

        }
    }
}

- (void)doneSelection
{
    DiaryEntryViewController *entryViewController = [[DiaryEntryViewController alloc]init];
    entryViewController.selectedMediaType = selectedMediaType;
    
    if (selectedMediaType == kMediaTypePhoto) {
        // Create Image from collection view
        UIGraphicsBeginImageContextWithOptions(diaryPhotosView.bounds.size, YES, [UIScreen mainScreen].scale);
        diaryPhotosView.backgroundColor = [UIColor whiteColor];
        [diaryPhotosView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *collectionViewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        entryViewController.diaryImage = collectionViewImage;
        entryViewController.imageMeta = imageMeta;
    } else {
        ALAsset *videoAsset = [photoAssets objectAtIndex:videoIndexPath.row];
        entryViewController.asset = videoAsset;
        entryViewController.diaryImage = videoImageView.image;
    }
    [self.navigationController pushViewController:entryViewController animated:YES];
}

-(void)cancelDiary
{
    if (_diary)
        [[DiaryDataStore sharedStore]removeItem:_diary];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)filteredImage:(UIImage *)fullImage andCropImage:(UIImage *)croppedImage indexPath:(NSIndexPath *)path
{
    // Replace image in fullscreenimage array
    fullScreenImageArray[path.row] = fullImage;
    CGSize cellSize = [sizeArray[path.row] CGSizeValue];
    if (croppedImage) {
        cellImageArray[path.row] = [croppedImage resizeImageToSize:cellSize];
        [diaryPhotosView reloadItemsAtIndexPaths:@[path]];
    } else {
        cellImageArray[path.row] = fullImage;
        [self processFaceDetectionWithIndexPath:@[path]];
    }
}

#pragma mark -Delete

- (void)showDeleteVideoButton:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        [anim setToValue:[NSNumber numberWithFloat:0.0f]];
        [anim setFromValue:[NSNumber numberWithDouble:M_PI/48]]; // rotation angle
        [anim setDuration:0.1];
        [anim setRepeatCount:1];
        [anim setAutoreverses:YES];
        [videoImageView.layer addAnimation:anim forKey:@"iconShake"];
        
        if (videoDeleteLabel.hidden) {
            videoDeleteLabel.hidden = NO;
            videoDeleteLabel.alpha = 0;
            [UIView animateWithDuration:0.5 animations:^{
                videoDeleteLabel.alpha = 1;
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^{
                videoDeleteLabel.alpha = 0;
            } completion:^(BOOL finished) {
                videoDeleteLabel.hidden = YES;
            }];
        }
    }
}

- (void)showDeleteButton:(UILongPressGestureRecognizer *)sender
{
    DiaryPhotoCell *cell = (DiaryPhotoCell *)sender.view;
    // Wobbly animation
    if (sender.state == UIGestureRecognizerStateBegan) {
        CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        [anim setToValue:[NSNumber numberWithFloat:0.0f]];
        [anim setFromValue:[NSNumber numberWithDouble:M_PI/48]]; // rotation angle
        [anim setDuration:0.1];
        [anim setRepeatCount:1];
        [anim setAutoreverses:YES];
        [cell.layer addAnimation:anim forKey:@"iconShake"];
        if (cell.deleteBadger.hidden) {
            cell.deleteBadger.hidden = NO;
            cell.deleteBadger.alpha = 0;
            [UIView animateWithDuration:0.5 animations:^{
                cell.deleteBadger.alpha = 1;
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^{
                cell.deleteBadger.alpha = 0;
            } completion:^(BOOL finished) {
                cell.deleteBadger.hidden = YES;
            }];
        }
    }
}

-(void)deleteTap:(UITapGestureRecognizer *)sender
{
    NSIndexPath *indexPath =  [diaryPhotosView indexPathForCell:(UICollectionViewCell *)sender.view.superview];
    NSArray *imageInfo = [selectedPhotoOrderingInfo objectAtIndex:indexPath.row];
    [photoCollectionView deselectItemAtIndexPath:imageInfo[0] animated:YES];
    if ([fullScreenImageArray[indexPath.row] isKindOfClass:[ALAsset class]])
        [self deletePhotoFromDiaryView:imageInfo[0] andAsset:fullScreenImageArray[indexPath.row]];
    else
        [self removePhotoWithIndexPath:indexPath];
}

-(void)deletePhotoFromDiaryView:(NSIndexPath *)indexPath andAsset:(ALAsset *)asset
{
    if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
        _noPhotoView.hidden = NO;
        [self cancelMPMoviePlayer];
        navItem.rightBarButtonItem.title = @"0/1";
    } else
        [self removePhotoWithIndexPath:indexPath];
}

#pragma mark - Photo collection view relate
#pragma mark

- (void)swipePhotoCollection:(UISwipeGestureRecognizer *)sender
{
    [self.view bringSubviewToFront:scroller];
    [self.view bringSubviewToFront:photoAlbumTable];
    [self.view bringSubviewToFront:photoCollectionView];
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

-(void)showNextButton:(BOOL)show
{
    if (show)
        [self.navigationItem setRightBarButtonItem:nextButton animated:YES];
    else
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (void)setupPhotoCollectionView
{
    NSArray *sourceKeys = photoLoader.sourceDictionary.allKeys;
    
    // Set up dictionary to preserve image and index path and album name
//    for (NSString *key in sourceKeys) {
//        NSMutableDictionary *photoGroupDict = [[NSMutableDictionary alloc]init];
//        [selectedPhotoInfo setValue:photoGroupDict forKey:key];
//    }
    
    NSString *sourceKey = sourceKeys[1];
    assetGroupPropertyName = sourceKey;
    
    photoAssets = [[NSMutableArray alloc]initWithArray:[[[photoLoader.sourceDictionary objectForKey:sourceKey] reverseObjectEnumerator] allObjects]];

    navItem.title = assetGroupPropertyName;
    [photoCollectionView reloadData];
}

- (void)reloadPhotoCollectionView:(NSMutableArray *)selectedAlbum
{
    photoAssets = [[NSMutableArray alloc]initWithArray:[[selectedAlbum reverseObjectEnumerator] allObjects]];
    
    [photoCollectionView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for (int i = 0; i< [selectedPhotoOrderingInfo count];i++) {
            NSArray *imageInfo = [selectedPhotoOrderingInfo objectAtIndex:i];
            if ([assetGroupPropertyName isEqualToString:imageInfo[1]]) {
                NSIndexPath *path = imageInfo[0];
                NSInteger selectNumber = i + 1;
                [photoCollectionView selectItemAtIndexPath:path animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
                AlbumPhotoCell *cell = (AlbumPhotoCell *)[photoCollectionView cellForItemAtIndexPath:path];
                cell.selectNumber.text = [NSString stringWithFormat:@"%ld", (long)selectNumber];
            }
        }
    });
}

- (void)selectedPhoto:(NSIndexPath *)indexPath
{
    if ([fullScreenImageArray count]==0)
        [self showNextButton:YES];
    _noPhotoView.hidden = YES;
    ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];

    // Save image meta data
    [imageMeta addObject:asset.defaultRepresentation.metadata];
    
    // Resize the image
    [fullScreenImageArray addObject:asset];
    navItem.rightBarButtonItem.title = [NSString stringWithFormat:@"%ld/5",(unsigned long)[fullScreenImageArray count]];
    
    AlbumPhotoCell *cell = (AlbumPhotoCell *)[photoCollectionView cellForItemAtIndexPath:indexPath];
    cell.selectNumber.text = [NSString stringWithFormat:@"%ld",(unsigned long)[fullScreenImageArray count]];
    
    // Photo collectionview image info
    // ImageInfo[0] = indexpath
    // ImageInfo[1] = assset group name
    NSArray *imageInfo = @[indexPath,assetGroupPropertyName,cell.selectNumber.text];
    [selectedPhotoOrderingInfo addObject:imageInfo];
    
    // Perform face detection and setup diary collection view
    [self processFaceDetection];
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

#pragma mark -Remove Photo

- (void)removePhotoWithIndexPath:(NSIndexPath *)path
{
    for (NSArray *imageInfo in selectedPhotoOrderingInfo) {
        
        // ImageInfo[0] = indexpath
        // ImageInfo[1] = assset group name
        // ImageInfo[2] = asset
        
        if (imageInfo[0] == path) {
            
            // Remove image from resize image array
            NSUInteger index = [selectedPhotoOrderingInfo indexOfObject:imageInfo];
            [imageMeta removeObjectAtIndex:index];
            [fullScreenImageArray removeObjectAtIndex:index];
            navItem.rightBarButtonItem.title = [NSString stringWithFormat:@"%ld/5",(unsigned long)[fullScreenImageArray count]];
            
            // Show "next" button
            if ([fullScreenImageArray count] <1)
                [self showNextButton:NO];
            
            // Remove image info from ordering info
            [selectedPhotoOrderingInfo removeObject:imageInfo];
            
            // Hide no photo view
            if([selectedPhotoOrderingInfo count]==0)
                _noPhotoView.hidden = NO;
            
            // Refresh selected number on cell
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
    
        if ([cellImageArray count] > 0)
            cell.photoView.image = cellImageArray[indexPath.row];
        
        [UIView animateWithDuration:0.5f animations:^{
            cell.photoView.frame = cell.contentView.bounds;

        }];
        
        // LongPress gesture to show delete button
        UILongPressGestureRecognizer *showDeleteButton = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(showDeleteButton:)];
        [cell addGestureRecognizer:showDeleteButton];
        
        // Tap gesture for delete cell
        UITapGestureRecognizer *deleteCellGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(deleteTap:)];
        [cell.deleteBadger addGestureRecognizer:deleteCellGesture];
        cell.deleteBadger.frame = CGRectMake(cell.contentView.bounds.size.width-deleteLabelSize-3,3, deleteLabelSize, deleteLabelSize);
        cell.deleteBadger.layer.borderColor = [[UIColor whiteColor]CGColor];
        cell.deleteBadger.layer.borderWidth = 2.0f;
        cell.deleteBadger.layer.cornerRadius = cell.deleteBadger.frame.size.width/2;
        cell.deleteBadger.hidden = YES;
        
        // Add gesture to each cell
        UIPanGestureRecognizer *panCell = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(movePhoto:)];
        [cell addGestureRecognizer:panCell];
        
        photoCollectionView.userInteractionEnabled = YES;

        return cell;
        
    } else {
        AlbumPhotoCell *cell = (AlbumPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"AlbumPhotoCell" forIndexPath:indexPath];
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        cell.asset = asset;
        
        cell.cellImageView.image = [UIImage imageWithCGImage: asset.thumbnail];
        
        for (int i = 0; i < [selectedPhotoOrderingInfo count] ; i++) {
            NSArray *imageInfo = [selectedPhotoOrderingInfo objectAtIndex:i];
            if(indexPath == imageInfo[0])
                cell.selectNumber.text = [NSString stringWithFormat:@"%d",i+1];
        }
        
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
            [cell formatVideoInterval:[asset valueForProperty:ALAssetPropertyDuration]];
        } else {
            cell.videoTimeLabel.hidden = YES;
            cell.videoLabel.hidden = YES;
        }
        return cell;
    }
}

#pragma mark -UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==0) {

        DiaryPhotoViewController *photoViewController = [[DiaryPhotoViewController alloc]init];
        photoViewController.cropRectSize = [sizeArray[indexPath.row] CGSizeValue];
        photoViewController.indexPath = indexPath;
        photoViewController.delegate = self;
        
        DiaryPhotoCell *selectedCell = (DiaryPhotoCell *)[diaryPhotosView cellForItemAtIndexPath:indexPath];
        selectedCell.deleteBadger.hidden = YES;
        
        ALAsset *asset;
        // If image has not been filtered , pass image from asset library
        if ([[fullScreenImageArray objectAtIndex:indexPath.row] isKindOfClass:[ALAsset class]]) {
            asset = [fullScreenImageArray objectAtIndex:indexPath.row];
            photoViewController.photoImage = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
        }
        // Otherwise , pass both original and filterd image
        else
            photoViewController.photoImage = [fullScreenImageArray objectAtIndex:indexPath.row];

        [self.navigationController pushViewController:photoViewController animated:YES];
    }
    // Photo collection view select
    else {
        photoCollectionView.userInteractionEnabled = NO;
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
            if ([fullScreenImageArray count] > 0) {
                [self cancelPhotoSelection];
            }
            if (videoIndexPath)
                [photoCollectionView deselectItemAtIndexPath:videoIndexPath animated:YES];
            
            navItem.rightBarButtonItem.title = @"1/1";
            videoIndexPath = indexPath;
            selectedMediaType = kMediaTypeVideo;
            UIImage *cellImage = [UIImage imageWithCGImage:[asset.defaultRepresentation fullScreenImage]];
            videoImageView.image = [cellImage cropWithFaceDetect:videoImageView.frame.size];
            
            [self hidePhoto];
            [self showVideo];

            photoCollectionView.userInteractionEnabled = YES;
            [self showNextButton:YES];
            
        } else if ([fullScreenImageArray count] < 5) {
            if (selectedMediaType != kMediaTypePhoto) {
                [self cancelMPMoviePlayer];
                selectedMediaType = kMediaTypePhoto;
            }
            [self hideVideo];
            [self showPhoto];
            [self selectedPhoto:indexPath];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag==1) {
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        [self deletePhotoFromDiaryView:indexPath andAsset:asset];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView.tag == 1) {
        ALAsset *asset =  [photoAssets objectAtIndex:indexPath.row];
        if ([asset valueForProperty:ALAssetPropertyType]==ALAssetTypePhoto) {
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
        } else
            return YES;
    }
    else
        return YES;
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

#pragma mark - Table Views

- (void)showTable
{
    [photoAlbumTable reloadData];
    
    if (!showAlbumTable) {
        photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, 320, 0);
        photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, -320, 0);
        showAlbumTable = YES;
    } else {
        photoCollectionView.frame = CGRectOffset(photoCollectionView.frame, -320, 0);
        photoAlbumTable.frame = CGRectOffset(photoAlbumTable.frame, 320, 0);
        showAlbumTable = NO;
    }
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotoAlbumTableCell";
    PhotoAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[PhotoAlbumTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSArray *souceKeys = photoLoader.sourceDictionary.allKeys;
    NSString *key = souceKeys[indexPath.row];
    cell.title.text = key;
    
    NSMutableArray *photoAlbum = [[photoLoader sourceDictionary] objectForKey:key];
    ALAsset *asset = [photoAlbum lastObject];
    cell.photoImageView.image = [UIImage imageWithCGImage: asset.thumbnail];
    cell.backgroundColor = [UIColor colorWithWhite:0.298 alpha:1.000];
    cell.detail.text = [NSString stringWithFormat:@"%ld Photos",(unsigned long)[photoAlbum count]];

    if ([key isEqualToString:assetGroupPropertyName]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark - Movie player
#pragma mark

-(void) playMovie
{
    ALAsset *videoAsset = [photoAssets objectAtIndex:videoIndexPath.row];
    videoPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL: videoAsset.defaultRepresentation.url];
    [videoPlayer.moviePlayer setContentURL:videoAsset.defaultRepresentation.url];
    
    [videoPlayer.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:1.0]] timeOption:MPMovieTimeOptionExact];
    // Setup the player
    videoPlayer.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    videoPlayer.moviePlayer.shouldAutoplay = YES;
    
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

- (void)cancelMPMoviePlayer
{
    navItem.rightBarButtonItem.title = @"0/5";
    [photoCollectionView deselectItemAtIndexPath:videoIndexPath animated:YES];
    [cellImageArray removeAllObjects];
    [self showNextButton:NO];
    videoIndexPath = nil;
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
//    [moviePlayer.view removeFromSuperview];
    
    // Stop before release to workaround iOS's bug
    [moviePlayer stop];
}

#pragma mark -
#pragma mark preparingAlertView Methods

- (void) launchPreparingAlertViewAlert {
	// Launch Downloading Alert
	if(preparingAlertView!=nil)	// Don't need to launch again
		return;
	
	preparingAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Loading..."
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

#pragma mark - Memory Warning
#pragma mark

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end