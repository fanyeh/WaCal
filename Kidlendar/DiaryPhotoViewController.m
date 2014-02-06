//
//  DiaryPhotoController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryPhotoViewController.h"
#import "GPUImage.h"

@interface DiaryPhotoViewController ()
{
    UIImage *filterImage;
}
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

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

    [_photoImageView setImage:_photoImage];
    filterImage = [[UIImage alloc]initWithData:UIImagePNGRepresentation(_photoImage)];
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

- (IBAction)filterActBtn:(UIButton *)sender
{
    switch (sender.tag) {
        case 0:
            // Polkadot
        {
            GPUImagePolkaDotFilter *filter = [[GPUImagePolkaDotFilter alloc]init];
            _photoImageView.image = [filter imageByFilteringImage:_photoImage];
        }
            break;
        case 1:
            // Amortorka
        {
            GPUImageAmatorkaFilter *filter = [[GPUImageAmatorkaFilter alloc]init];
            _photoImageView.image = [filter imageByFilteringImage:_photoImage];
        }
            break;
        case 2:
            // Sketch
        {
            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc]init];
            _photoImageView.image = [filter imageByFilteringImage:_photoImage];
        }
            break;
        case 3:
            // SmoothToon
        {
            GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc]init];
            _photoImageView.image = [filter imageByFilteringImage:_photoImage];
        }
            break;
        case 4:
            // Pinch
        {
            GPUImagePinchDistortionFilter *filter = [[GPUImagePinchDistortionFilter alloc]init];
            _photoImageView.image = [filter imageByFilteringImage:_photoImage];
        }
            break;
        default:
            break;
    }
}

- (void)done
{
    [_PassFilteredImageDelegate filteredImage:_photoImageView.image index:_index];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
