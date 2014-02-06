//
//  ProfileViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/31.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "ProfileViewController.h"
#import "ProfileImageStore.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *birthDayTextField;

@end

@implementation ProfileViewController

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
    
    // Put that image onto the screen in our image view
    UIImage *image = [[ProfileImageStore sharedStore]imageForKey:_profile.imageKey];
    
    [_profileImage setContentMode:UIViewContentModeScaleAspectFit];
    _profileImage.image = image;
    _nameTextField.text = _profile.name;
    NSDate *birthDate = [NSDate dateWithTimeIntervalSince1970:_profile.birthDate];
    _birthDayTextField.text = [NSString stringWithFormat:@"%@",birthDate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
