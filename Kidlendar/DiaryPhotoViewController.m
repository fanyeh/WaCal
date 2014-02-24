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
