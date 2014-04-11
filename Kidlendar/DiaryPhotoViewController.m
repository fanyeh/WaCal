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

@interface DiaryPhotoViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
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
    UIImage *filteredImage;
    CGSize sizeAfterAspectFit;
    CGPoint photoCenter;
    CGFloat initialRectRatio;
    CGFloat sliderHeight;
}
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *filterCollectionView;
@property (weak, nonatomic) IBOutlet GPUImageView *filterView;
@property (weak, nonatomic) IBOutlet UISlider *adjustSlider;
@property (weak, nonatomic) IBOutlet UIView *adjustSliderView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *cropButton;
@property (weak, nonatomic) IBOutlet UIButton *brightnessButton;

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
    
    filteredImage = _photoImage;
    _photoImageView.image = _photoImage;
    [_photoImageView addGestureRecognizer:pan];

    CGSize screenSize = [[UIScreen mainScreen]bounds].size;
    if (screenSize.height == 480) {
        self.view.frame = CGRectMake(0, 0, 320, 480);
        _photoImageView.frame = CGRectMake(0,44, 320, 320);
        _toolBarView.frame = CGRectMake(0,364, 320, 35);
        _filterCollectionView.frame = CGRectMake(0,399, 320, 81);
        _adjustSliderView.frame = CGRectMake(0, 480, 320, 116);
        sliderHeight = 116;
    } else
        sliderHeight = 150;
    
    // Adjust image view to fit photo
    sizeAfterAspectFit = [self imageSizeAfterAspectFit:_photoImageView];
    photoCenter = _photoImageView.center;
    _photoImageView.frame = CGRectMake(_photoImageView.frame.origin.x,
                                       _photoImageView.frame.origin.y,
                                       sizeAfterAspectFit.width,
                                       sizeAfterAspectFit.height);
    _photoImageView.center = photoCenter;
    _filterView.frame = _photoImageView.frame;
    initialRectRatio = 1;
    
    // Adjust cropRect size proportionally based on collection view cell size
    _cropRectSize = [self resizeCropSize:_cropRectSize];
    if (_cropRectSize.width == _photoImageView.frame.size.width && _cropRectSize.height == _photoImageView.frame.size.height) {
        _cropButton.hidden = YES;
    }

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
            [filterImageArray addObject:[_photoImage resizeImageToSize:cellSize]];
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
//    CGPathAddPath(p1, nil, CGPathCreateWithRect(_photoImageView.bounds, nil));
    CGPathAddPath(p1, nil, CGPathCreateWithRect(_photoImageView.bounds, nil));

    _maskLayer.path = p1;
    CGPathRelease(p1);

    // display the path of the masks the for screenshot
    borderLayer.path = CGPathCreateWithRect(cropRect,nil);
    borderLayer.lineWidth = 3.0f;
    borderLayer.strokeColor = [UIColor clearColor].CGColor;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
}

- (void)createCropMask
{
    // Setup crop rect

    if (_cropRectSize.width == _photoImageView.frame.size.width) {
        _cropRect = CGRectMake(_photoImageView.bounds.origin.x ,
                               _photoImageView.frame.size.height/2 - _cropRectSize.height/2,
                               _cropRectSize.width,
                               _cropRectSize.height);
    } else if (_cropRectSize.height == _photoImageView.frame.size.height) {
        _cropRect = CGRectMake(_photoImageView.frame.size.width/2 - _cropRectSize.width/2,
                               _photoImageView.bounds.origin.y ,
                               _cropRectSize.width,
                               _cropRectSize.height);
    } else {
        _cropRect = CGRectMake(_photoImageView.frame.size.width/2 - _cropRectSize.width/2,
                               _photoImageView.frame.size.height/2 - _cropRectSize.height/2,
                               _cropRectSize.width,
                               _cropRectSize.height);
    }

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
    [self.view.layer addSublayer:imageLayer];
}

- (CGSize)resizeCropSize:(CGSize)cropRectSize
{
    CGFloat imageWidth = sizeAfterAspectFit.width;
    CGFloat imageHeight =  sizeAfterAspectFit.height;
    
    CGFloat cropRatio = cropRectSize.width/cropRectSize.height;
    
    CGFloat maxCropHeight = imageWidth/cropRatio;
    CGFloat maxCropWidth = imageWidth;
    
    if (maxCropHeight > imageHeight) {
        maxCropHeight = imageHeight;
        maxCropWidth = imageHeight*cropRatio;
    }
    return CGSizeMake(maxCropWidth*initialRectRatio, maxCropHeight*initialRectRatio);
}

-(CGSize)imageSizeAfterAspectFit:(UIImageView*)imgview
{
    float newwidth;
    float newheight;
    
    UIImage *image=imgview.image;
    
    if (image.size.height>=image.size.width){
        newheight=imgview.frame.size.height;
        newwidth=(image.size.width/image.size.height)*newheight;
        
        if(newwidth>imgview.frame.size.width){
            float diff=imgview.frame.size.width-newwidth;
            newheight=newheight+diff/newheight*newheight;
            newwidth=imgview.frame.size.width;
        }
        
    }
    else{
        newwidth=imgview.frame.size.width;
        newheight=(image.size.height/image.size.width)*newwidth;
        
        if(newheight>imgview.frame.size.height){
            float diff=imgview.frame.size.height-newheight;
            newwidth=newwidth+diff/newwidth*newwidth;
            newheight=imgview.frame.size.height;
        }
    }
    
    sizeAfterAspectFit = CGSizeMake(newwidth, newheight);
    return sizeAfterAspectFit;
}

- (void)handlePan:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:self.view];
    _cropRect = CGRectOffset(_cropRect, translation.x, translation.y);
    
    CGRect frame = _cropRect;
    CGFloat gapFromBoundary = 0;
    
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
    
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded) {
        _cropRect = frame;
        [self updateMaskPath:_cropRect];
    }
}

-(CGRect)scaleCropRect
{
    CGFloat widthRatio = _photoImage.size.width/sizeAfterAspectFit.width;
    CGFloat heightRatio = _photoImage.size.height/sizeAfterAspectFit.height;

    CGAffineTransform t = CGAffineTransformMakeScale(widthRatio/initialRectRatio,heightRatio/initialRectRatio);
    CGRect scaledCropRect = CGRectApplyAffineTransform(_cropRect,t);
    
    return scaledCropRect;
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
        
        UIImage *croppedImage = [_photoImageView.image cropImageWithRectImageView:[self scaleCropRect] view:_photoImageView];
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
        _photoImageView.image = _photoImage;
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
    
    filteredImage = _photoImageView.image;
    stillImageSource = [[GPUImagePicture alloc] initWithImage:filteredImage];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize screenSzie = [[UIScreen mainScreen]bounds].size;
    if (screenSzie.height == 480) {
        return CGSizeMake(71 , 71);
    }
    else
        return CGSizeMake(70, 100);
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
    stillImageSource = [[GPUImagePicture alloc] initWithImage:filteredImage];
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
        [_cropButton setImage:[UIImage imageNamed:@"cropWhite35.png"] forState:UIControlStateNormal];
    } else {
        isCrop = YES;
        [self createCropMask];
        _photoImageView.userInteractionEnabled = YES;
        [_cropButton setImage:[UIImage imageNamed:@"crop35.png"] forState:UIControlStateNormal];
    }
}

// Slider
- (IBAction)adjust:(UISlider *)sender
{
    if (filter == kFilterTypeBrightness) {
        brightnessFilter.brightness = sender.value;
        [stillImageSource processImage];
    }
    _photoImageView.hidden = YES;
}

// Slider view cancel button
- (IBAction)cancelSlider:(id)sender
{
    if (brightnessFilter.brightness == 0)
        [_brightnessButton setImage:[UIImage imageNamed:@"brightnessWhite35.png"] forState:UIControlStateNormal];
    else
        [_brightnessButton setImage:[UIImage imageNamed:@"brightness35.png"] forState:UIControlStateNormal];
    [exposureFilter removeAllTargets];
    [self hideSlider];
}

// Slider view done button
- (IBAction)getProcessedImage:(id)sender
{
    if (brightnessFilter.brightness == 0)
        [_brightnessButton setImage:[UIImage imageNamed:@"brightnessWhite35.png"] forState:UIControlStateNormal];
    else
        [_brightnessButton setImage:[UIImage imageNamed:@"brightness35.png"] forState:UIControlStateNormal];

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
        _adjustSliderView.frame = CGRectOffset(_adjustSliderView.frame, 0, -sliderHeight);
        
    }];
}

- (void)hideSlider
{
    _photoImageView.hidden = NO;
    _filterView.hidden = YES;
    [UIView animateWithDuration:0.3f animations:^{
        _adjustSliderView.frame = CGRectOffset(_adjustSliderView.frame, 0, sliderHeight);
        
    } completion:^(BOOL finished) {
        _adjustSliderView.hidden = YES;
        
    }];
}
- (IBAction)resetBrightNess:(id)sender
{
    brightnessFilter.brightness = 0;
    _adjustSlider.value = 0;
    [stillImageSource processImage];
}

@end
