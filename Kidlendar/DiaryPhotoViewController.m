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
    CGRect _cropRect;
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
    // Add save button on navigation controller
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                               target:self
                                                                               action:@selector(done)];
    
    self.navigationItem.rightBarButtonItem = saveButton;
    
    _filterCollectionView.allowsMultipleSelection = NO;
    [_filterCollectionView registerClass:[FilterCell class] forCellWithReuseIdentifier:@"FilterCell"];
    _filterCollectionView.delegate = self;
    _filterCollectionView.dataSource = self;
    
    
    _photoImage = [_photoImage cropWithFaceDetect:_photoImageView.frame.size];
    _photoImageView.image = _photoImage;
    
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
    
    self.view.backgroundColor = [UIColor blackColor];
    
    _cropRect = CGRectMake(80, 80, 200, 200);

    // create layer mask for the image
    
    _maskLayer =[[CAShapeLayer alloc]init];
    _maskLayer.frame = self.view.frame;
    _maskLayer.fillRule = kCAFillRuleEvenOdd;
    
//    _photoImageView.layer.mask = _maskLayer;

    CGMutablePathRef p1 = CGPathCreateMutable();
    CGPathAddPath(p1, nil, CGPathCreateWithRect((CGRect){{100, 140}, {100, 150}}, nil));
    CGPathAddPath(p1, nil, CGPathCreateWithRect((CGRect){{0, 0}, {320, 568}}, nil));
    _maskLayer.path = p1;
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = _photoImageView.frame;
    imageLayer.backgroundColor = [[UIColor colorWithWhite:0.000 alpha:0.510] CGColor];
    imageLayer.mask = _maskLayer;
    
    [self.view.layer addSublayer:imageLayer];
    // display the path of the masks the for screenshot
    CAShapeLayer *pathLayer1 = [CAShapeLayer layer];
    pathLayer1.path = CGPathCreateWithRect(CGRectMake(100, 140,100, 150),nil);
    pathLayer1.lineWidth = 2.0;
    pathLayer1.strokeColor = [UIColor yellowColor].CGColor;
    pathLayer1.fillColor = [UIColor clearColor].CGColor;
    [imageLayer addSublayer:pathLayer1];
    
    // create pan gesture
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_photoImageView addGestureRecognizer:pan];
    _photoImageView.userInteractionEnabled = YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{

    CGPoint translation = [gesture translationInView:self.view];
    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x,
                                         gesture.view.center.y + translation.y);
    
    [gesture setTranslation:CGPointMake(0, 0) inView:self.view];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done
{
    [_delegate filteredImage:_photoImageView.image indexPath:_indexPath];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FilterCell *cell = (FilterCell *)[collectionView cellForItemAtIndexPath:indexPath];
    _photoImageView.image = cell.cellImageView.image;
}

#pragma mark - UIColeectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [filterName count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FilterCell *cell = (FilterCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FilterCell" forIndexPath:indexPath];
    if (indexPath.row == 0)
        cell.cellImageView.image = [filterContainter objectAtIndex:indexPath.row];
    else
        cell.cellImageView.image =[[filterContainter objectAtIndex:indexPath.row]imageByFilteringImage:_photoImage];
    
    cell.filterNameLabel.text = [filterName objectAtIndex:indexPath.row];
    
    return cell;
}

@end
