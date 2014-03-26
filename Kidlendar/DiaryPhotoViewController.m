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

typedef NS_ENUM(NSInteger, FilterType)
{
    kFilterTypeExposure,
    kFilterTypeContrast,
    kFilterTypeBrightness,
    kFilterTypeSharpen
};

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
    FilterType filter;

    GPUImageContrastFilter *contrastFilter;
    GPUImageExposureFilter *exposureFilter;
    GPUImageBrightnessFilter *brightnessFilter;
    
    GPUImagePicture *stillImageSource;
    
    BOOL isCrop;
}
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *filterCollectionView;
@property (weak, nonatomic) IBOutlet GPUImageView *filterView;
@property (weak, nonatomic) IBOutlet UISlider *adjustSlider;
@property (weak, nonatomic) IBOutlet UIView *adjustSliderView;

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
    
    if (!_photoImage) {
        _originalImage = [[_originalImage cropWithFaceDetect:_photoImageView.frame.size] resizeImageToSize:_photoImageView.frame.size];
        _photoImage = _originalImage;
    } else {
        _originalImage = [[_originalImage cropWithFaceDetect:_photoImageView.frame.size] resizeImageToSize:_photoImageView.frame.size];
        _photoImage = [[_photoImage cropWithFaceDetect:_photoImageView.frame.size] resizeImageToSize:_photoImageView.frame.size];
    }
    _photoImageView.image = _photoImage;
    [_photoImageView addGestureRecognizer:pan];

    // Filters
    _filterCollectionView.allowsMultipleSelection = NO;
    [_filterCollectionView registerClass:[FilterCell class] forCellWithReuseIdentifier:@"FilterCell"];
    _filterCollectionView.delegate = self;
    _filterCollectionView.dataSource = self;

    
    //  GPUImageAmatorkaFilter
    GPUImageAmatorkaFilter *AmatorkaFilter = [[GPUImageAmatorkaFilter alloc]init];
    
    //  GPUImageMissEtikateFilter
    GPUImageMissEtikateFilter *missEtikateFilter = [[GPUImageMissEtikateFilter alloc]init];
    
    //  GPUImageSoftEleganceFilter
    GPUImageSoftEleganceFilter *softEleganceFilter = [[GPUImageSoftEleganceFilter alloc]init];
    
    //  GPUImageSketchFilter
    GPUImageSketchFilter *SketchFilter = [[GPUImageSketchFilter alloc]init];
    
    //  GPUImageSmoothToonFilter
    GPUImageSmoothToonFilter *SmoothToonFilter = [[GPUImageSmoothToonFilter alloc]init];
    
    //  GPUImageColorInvertFilter
    GPUImageColorInvertFilter *colorInventFilter = [[GPUImageColorInvertFilter alloc]init];
    
    //  GPUImageGrayscaleFilter
    GPUImageGrayscaleFilter *grayScaleFilter = [[GPUImageGrayscaleFilter alloc]init];
        
    //  GPUImageSepiaFilter: Simple sepia tone filter
    //  intensity: The degree to which the sepia tone replaces the normal image color (0.0 - 1.0, with 1.0 as the default)
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc]init];
    
    //  GPUImageKuwaharaFilter:
    //  radius: In integer specifying the number of pixels out from the center pixel to test when applying the filter, with a default of 4.
    //  A higher value creates a more abstracted image, but at the cost of much greater processing time.
    GPUImageKuwaharaFilter *kuwaharaFilter = [[GPUImageKuwaharaFilter alloc]init];
    
    //  GPUImageSharpenFilter: Sharpens the image
    //  sharpness: The sharpness adjustment to apply (-4.0 - 4.0, with 0.0 as the default)
    GPUImageSharpenFilter *sharpenFilter = [[GPUImageSharpenFilter alloc]init];
    sharpenFilter.sharpness = 0.3;
    
    
    //  GPUImageMonochromeFilter: Converts the image to a single-color version, based on the luminance of each pixel
    //  intensity: The degree to which the specific color replaces the normal image color (0.0 - 1.0, with 1.0 as the default)
    //  color: The color to use as the basis for the effect, with (0.6, 0.45, 0.3, 1.0) as the default.
    
    //  GPUImagePolkaDotFilter
    //  fractionalWidthOfAPixel: How large the dots are, as a fraction of the width and height of the image (0.0 - 1.0, default 0.05)
    //  dotScaling: What fraction of each grid space is taken up by a dot, from 0.0 to 1.0 with a default of 0.9.
    //  GPUImagePolkaDotFilter *polkaDotFilter = [[GPUImagePolkaDotFilter alloc]init];
    
    
    // **** Put on tool bar ****

    //  GPUImageContrastFilter
    //  contrast: The adjusted contrast (0.0 - 4.0, with 1.0 as the default)
    contrastFilter = [[GPUImageContrastFilter alloc]init];
    contrastFilter.contrast = 1.25;
    //  GPUImageExposureFilter
    //  exposure: The adjusted exposure (-10.0 - 10.0, with 0.0 as the default)
    exposureFilter = [[GPUImageExposureFilter alloc]init];
    
    //  GPUBrightnessFilter
    //  brightness: The adjusted brightness (-1.0 - 1.0, with 0.0 as the default)
    brightnessFilter = [[GPUImageBrightnessFilter alloc]init];

    filterName = @[@"Origin",
                   @"Sharpen",
                   @"Jungle",
                   @"Sky",
                   @"Coffee",
                   @"Vintage",
                   @"B&W",
                   @"Sketch",
                   @"Toon",
                   @"Film",
                   @"Paint"];
    
    filterContainter = @[@"Origin",
                         sharpenFilter,
                         AmatorkaFilter,
                         missEtikateFilter,
                         softEleganceFilter,
                         sepiaFilter,
                         grayScaleFilter,
                         SketchFilter,
                         SmoothToonFilter,
                         colorInventFilter,
                         kuwaharaFilter,
                         ];
    
    filterImageArray = [[NSMutableArray alloc]init];
    CGSize cellSize = CGSizeMake(70, 70);
    for (int i = 0;i<[filterName count]; i++) {
        if (i == 0)
            [filterImageArray addObject:[_originalImage resizeImageToSize:cellSize]];
        else
            [filterImageArray addObject:[[filterContainter objectAtIndex:i]imageByFilteringImage:[_photoImage resizeImageToSize:cellSize]]];
    }
    
    isCrop = NO;
}

- (void)updateMaskPath:(CGRect)cropRect
{
    // Create mask Path
    CGMutablePathRef p1 = CGPathCreateMutable();
    CGPathAddPath(p1, nil, CGPathCreateWithRect(cropRect, nil));
    CGPathAddPath(p1, nil, CGPathCreateWithRect(_photoImageView.bounds, nil));
    _maskLayer.path = p1;
    CGPathRelease(p1);

    // display the path of the masks the for screenshot
    borderLayer.path = CGPathCreateWithRect(cropRect,nil);
    borderLayer.lineWidth = 3.0f;
    borderLayer.strokeColor = [UIColor yellowColor].CGColor;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
}

- (void)createCropMask
{
    CGRect imageBounds = _photoImageView.bounds;
    CGPoint boundsCenter;
    boundsCenter.x = (imageBounds.origin.x + imageBounds.size.width)/2;
    boundsCenter.y = (imageBounds.origin.y + imageBounds.size.height)/2;
    
    // Adjust cropRect size proportionally based on collection view cell size
    _cropRectSize = [self resizeCropSize:_cropRectSize];
    
    // Setup crop rect
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
    imageLayer.backgroundColor = [[UIColor colorWithWhite:0.000 alpha:0.600] CGColor];
    imageLayer.mask = _maskLayer;
    [imageLayer addSublayer:borderLayer];
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
    if (isCrop) {
        UIImage *croppedImage = [_photoImageView.image cropImageWithRectImageView:_cropRect view:_photoImageView];
        [_delegate filteredImage:_photoImageView.image andCropImage:croppedImage indexPath:_indexPath];
    } else {
        [_delegate filteredImage:_photoImageView.image andCropImage:nil indexPath:_indexPath];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        _photoImageView.image = _originalImage;
    else if (indexPath.row == 2) {
        GPUImageAmatorkaFilter *amatorkaFilter = [[GPUImageAmatorkaFilter alloc]init];
        _photoImageView.image = [amatorkaFilter imageByFilteringImage:_photoImage];
    }
    else if (indexPath.row == 3) {
        //  GPUImageMissEtikateFilter
        GPUImageMissEtikateFilter *missEtikateFilter = [[GPUImageMissEtikateFilter alloc]init];
        _photoImageView.image = [missEtikateFilter imageByFilteringImage:_photoImage];
    }
    else if (indexPath.row == 4) {
        //  GPUImageSoftEleganceFilter
        GPUImageSoftEleganceFilter *softEleganceFilter = [[GPUImageSoftEleganceFilter alloc]init];
        _photoImageView.image = [softEleganceFilter imageByFilteringImage:_photoImage];
    }
    else {
        _photoImageView.image = [[filterContainter objectAtIndex:indexPath.row]imageByFilteringImage:_photoImage];
    }
    
    _photoImage = _photoImageView.image;
    stillImageSource = [[GPUImagePicture alloc] initWithImage:_photoImageView.image];
    [stillImageSource addTarget:brightnessFilter];
    [stillImageSource processImage];
    [brightnessFilter endProcessing];
    _photoImageView.image = [brightnessFilter imageFromCurrentlyProcessedOutput];
    [stillImageSource removeAllTargets];
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

#pragma mark - User actions

- (IBAction)brightness:(id)sender
{
    //  brightness: The adjusted brightness (-1.0 - 1.0, with 0.0 as the default)
    [brightnessFilter addTarget:_filterView];
    filter = kFilterTypeBrightness;
    _adjustSlider.minimumValue = -0.5f;
    _adjustSlider.maximumValue = 0.5f;
    [_adjustSlider setValue:brightnessFilter.brightness animated:NO];
    stillImageSource = [[GPUImagePicture alloc] initWithImage:_photoImage];
    [stillImageSource addTarget:brightnessFilter];
    [stillImageSource processImage];
    [self showSlider];
}

//// Exposure Bar Button
//- (IBAction)exposure:(id)sender
//{
//    [exposureFilter addTarget:_filterView];
//    filter = kFilterTypeExposure;
//    _adjustSlider.minimumValue = -2.0f;
//    _adjustSlider.maximumValue = 2.0f;
//    [_adjustSlider setValue:exposureFilter.exposure animated:NO];
//    stillImageSource = [[GPUImagePicture alloc] initWithImage:_photoImage];
//    [stillImageSource addTarget:exposureFilter];
//    [stillImageSource processImage];
//    [self showSlider];
//}
//
//- (IBAction)contrast:(id)sender
//{
//    //  contrast: The adjusted contrast (0.0 - 4.0, with 1.0 as the default)
//
//    [contrastFilter addTarget:_filterView];
//    filter = kFilterTypeContrast;
//    _adjustSlider.minimumValue = 0.5f;
//    _adjustSlider.maximumValue = 2.0f;
//    [_adjustSlider setValue:contrastFilter.contrast animated:NO];
//    stillImageSource = [[GPUImagePicture alloc] initWithImage:_photoImage];
//    [stillImageSource addTarget:contrastFilter];
//    [stillImageSource processImage];
//    [self showSlider];
//}

- (IBAction)showCrop:(id)sender
{
    if (isCrop) {
        isCrop = NO;
        [imageLayer removeFromSuperlayer];
        _photoImageView.userInteractionEnabled = NO;
    } else {
        isCrop = YES;
        [self createCropMask];
        _photoImageView.userInteractionEnabled = YES;
    }
}

// Slider
- (IBAction)adjust:(UISlider *)sender
{
    if (filter == kFilterTypeBrightness) {
        brightnessFilter.brightness = sender.value;
        [stillImageSource processImage];
    }
//    if (filter == kFilterTypeExposure) {
//        exposureFilter.exposure = sender.value;
//        [stillImageSource processImage];
//    } else if (filter == kFilterTypeBrightness) {
//        brightnessFilter.brightness = sender.value;
//        [stillImageSource processImage];
//    } else if (filter == kFilterTypeContrast) {
//        contrastFilter.contrast = sender.value;
//        [stillImageSource processImage];
//    }
    _photoImageView.hidden = YES;
}

// Slider view cancel button
- (IBAction)cancelSlider:(id)sender
{
    //    _photoImageView.image = _photoImage;
    [exposureFilter removeAllTargets];
    [self hideSlider];
}

// Slider view done button
- (IBAction)getProcessedImage:(id)sender
{
    [brightnessFilter endProcessing];
    _photoImageView.image = [brightnessFilter imageFromCurrentlyProcessedOutput];
    [brightnessFilter removeAllTargets];
    [self hideSlider];
}

- (void)showSlider
{
    _filterView.hidden = NO;
    _adjustSliderView.hidden = NO;
    [UIView animateWithDuration:0.3f animations:^{
        _adjustSliderView.frame = CGRectOffset(_adjustSliderView.frame, 0, -160);
        
    }];
}

- (void)hideSlider
{
    _photoImageView.hidden = NO;
    _filterView.hidden = YES;
    [UIView animateWithDuration:0.3f animations:^{
        _adjustSliderView.frame = CGRectOffset(_adjustSliderView.frame, 0, 160);
        
    } completion:^(BOOL finished) {
        _adjustSliderView.hidden = YES;
        
    }];
}

@end
