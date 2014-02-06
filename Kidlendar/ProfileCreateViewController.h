//
//  KidProfileViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ProfileData;

@interface ProfileCreateViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *birthdayTextField;
@property (weak, nonatomic) IBOutlet UIImageView *maleImageView;
@property (weak, nonatomic) IBOutlet UIImageView *femaleImageView;
@property (nonatomic,strong) ProfileData *profile;

@end
