//
//  DiaryPhotoController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryPhotoViewController.h"
#import "GPUImage.h"
#import "FilterCell.h"
#import "UIImage+Resize.h"

@interface DiaryPhotoViewController () <UICollectionViewDataSource,UICollectionViewDelegate>
{
    NSArray *filterContainter;
    NSArray *filterName;
    CAShapeLayer *_maskLayer;
    CAShapeLayer *_cropLayer;
    CALayer *imageLayer;
    CAShapeLayer *borderLayer;
    CGRect _cropRect;
    UIPanGestureRecognizer *pan;
    NSMutableArray *filterImageArray;
}
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *filterCollectionView;

@end

@implementation DiaryPhotoViewController

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
    self.navigationItem.title = @"Edit Photo";

    // Add save button on navigation controller

    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                               target:self
                                                                               action:@selector(done)];
    
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // create crop rect pan gesture
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    
    _photoImage = [_photoImage cropWithFaceDetect:_photoImageView.frame.size];
    _photoImageView.image = _photoImage;
    [_photoImageView addGestureRecognizer:pan];

    
    // Filters
    _filterCollectionView.allowsMultipleSelection = NO;
    [_filterCollectionView registerClass:[FilterCell class] forCellWithReuseIdentifier:@"FilterCell"];
    _filterCollectionView.delegate = self;
    _filterCollectionView.dataSource = self;
    
    GPUImagePolkaDotFilter *polkaDotFilter = [[GPUImagePolkaDotFilter alloc]init];
    GPUImageAmatorkaFilter *AmatorkaFilter = [[GPUImageAmatorkaFilter alloc]init];
    GPUImageSketchFilter *SketchFilter = [[GPUImageSketchFilter alloc]init];
    GPUImageSmoothToonFilter *SmoothToonFilter = [[GPUImageSmoothToonFilter alloc]init];
    GPUImagePinchDistortionFilter *pinchDistortionFilter = [[GPUImagePinchDistortionFilter alloc]init];
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc]init];
    GPUImageExposureFilter *exposureFilter = [[GPUImageExposureFilter alloc]init];
    exposureFilter.exposure = 1;
    
    filterName = @[@"Origin",@"Polka", @"Amatorka",@"Sketch",@"SmoothToon",@"Pinch",@"Contrast",@"Exposure"];
    filterContainter = @[_photoImage,polkaDotFilter,AmatorkaFilter,SketchFilter,SmoothToonFilter,pinchDistortionFilter,contrastFilter,exposureFilter];
    
    filterImageArray = [[NSMutableArray alloc]init];
    CGSize cellSize = CGSizeMake(70, 70);
    for (int i = 0;i<[filterName count]; i++) {
        if (i == 0)
            [filterImageArray addObject:[_photoImage resizeImageToSize:cellSize]];
        else
            [filterImageArray addObject:[[filterContainter objectAtIndex:i]imageByFilteringImage:[_photoImage resizeImageToSize:cellSize]]];
    }
    
    [self createImageMask];
    
    [self.view.layer addSublayer:imageLayer];
}

- (CGSize)resizeCropSize:(CGSize)newSize
{
    CGFloat imageRatio = _photoImageView.frame.size.width/_photoImageView.frame.size.height;
    
    CGFloat gapFromBoundary = 30;
    CGFloat imageWidth = _photoImageView.frame.size.width - (gapFromBoundary*imageRatio);
    CGFloat imageHeight =  _photoImageView.frame.size.height - gapFromBoundary;
    
    CGFloat cropRatio = newSize.width/newSize.height;
    
    CGFloat maxCropHeight = imageWidth/cropRatio;
    CGFloat maxCropWidth = imageWidth;
    
    if (maxCropHeight > imageHeight) {
        maxCropHeight = imageHeight;
        maxCropWidth = imageHeight*cropRatio;
    }
    return CGSizeMake(maxCropWidth, maxCropHeight);
}

- (void)updateMaskPath:(CGRect)cropRect
{
    // Create mask Path
    CGMutablePathRef p1 = CGPathCreateMutable();
    CGPathAddPath(p1, nil, CGPathCreateWithRect(cropRect, nil));
    CGPathAddPath(p1, nil, CGPathCreateWithRect(_photoImageView.bounds, nil));
    _maskLayer.path = p1;
    
    // display the path of the masks the for screenshot
    borderLayer.path = CGPathCreateWithRect(cropRect,nil);
    borderLayer.lineWidth = 3.0f;
    borderLayer.strokeColor = [UIColor yellowColor].CGColor;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
}

- (void)createImageMask
{
    CGRect imageBounds = _photoImageView.bounds;
    CGPoint boundsCenter;
    boundsCenter.x = (imageBounds.origin.x + imageBounds.size.width)/2;
    boundsCenter.y = (imageBounds.origin.y + imageBounds.size.height)/2;
    
    _cropRectSize = [self resizeCropSize:_cropRectSize];
    
    _cropRect = CGRectMake(boundsCenter.x - _cropRectSize.width/2 ,
                           boundsCenter.y - _cropRectSize.height/2,
                           _cropRectSize.width,
                           _cropRectSize.height);
    
    // create layer mask for the image
    _maskLayer =[[CAShapeLayer alloc]init];
    _maskLayer.frame = _photoImageView.bounds;
    _maskLayer.fillRule = kCAFillRuleEvenOdd;
    
    borderLayer = [CAShapeLayer layer];
    
    [self updateMaskPath:_cropRect];
    
    imageLayer = [CALayer layer];
    imageLayer.frame = _photoImageView.frame;
    imageLayer.backgroundColor = [[UIColor colorWithWhite:0.000 alpha:0.700] CGColor];
    imageLayer.mask = _maskLayer;
    [imageLayer addSublayer:borderLayer];
}


- (void)handlePan:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:self.view];
    _cropRect = CGRectOffset(_cropRect, translation.x, translation.y);
    
    CGRect frame = _cropRect;


    CGFloat gapFromBoundary = 1;
    
    if (frame.origin.x < _photoImageView.bounds.origin.x)
        frame.origin.x = _photoImageView.bounds.origin.x + gapFromBoundary;
    
    if (frame.origin.y < _photoImageView.bounds.origin.y)
        frame.origin.y = _photoImageView.bounds.origin.y + gapFromBoundary;
    
    if (frame.origin.x+frame.size.width > _photoImageView.bounds.origin.x + _photoImageView.bounds.size.width)
        frame.origin.x = _photoImageView.bounds.origin.x+_photoImageView.bounds.size.width-gapFromBoundary-frame.size.width;
    
    
    if (frame.origin.y+frame.size.height > _photoImageView.bounds.origin.y + _photoImageView.bounds.size.height)
        frame.origin.y = _photoImageView.bounds.origin.y + _photoImageView.bounds.size.height-gapFromBoundary-frame.size.height;
    
    _cropRect = frame;

    
    [self updateMaskPath:_cropRect];
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done
{
     [_delegate filteredImage:[_photoImageView.image cropImageWithRectImageView:_cropRect view:_photoImageView] indexPath:_indexPath];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        _photoImageView.image = _photoImage;
    else if (indexPath.row == 2) {
        GPUImageAmatorkaFilter *amatorkaFilter = [[GPUImageAmatorkaFilter alloc]init];
        _photoImageView.image = [amatorkaFilter imageByFilteringImage:_photoImage];
    }
        
    else
        _photoImageView.image = [[filterContainter objectAtIndex:indexPath.row]imageByFilteringImage:_photoImage];
}

#pragma mark - UIColeectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [filterImageArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FilterCell *cell = (FilterCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FilterCell" forIndexPath:indexPath];
    cell.cellImageView.image = [filterImageArray objectAtIndex:indexPath.row];
    cell.filterNameLabel.text = [filterName objectAtIndex:indexPath.row];
    return cell;
}

@end
