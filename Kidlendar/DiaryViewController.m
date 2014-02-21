//
//  DiaryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryViewController.h"
#import "DiaryData.h"
#import <FacebookSDK/FacebookSDK.h>
#import "KidlendarAppDelegate.h"
#import "DropboxModel.h"
#import <Dropbox/Dropbox.h>
#import "CloudData.h"
#import "FacebookModel.h"

@interface DiaryViewController () <FBLoginViewDelegate>
{
    DropboxModel *DBModel;
}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetailTextView;

@end

@implementation DiaryViewController

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
    
    // Get photo from  use diary data key
    
    // Put that image onto the screen in our image view
    _diaryPhoto.image = _diaryData.diaryImage;
    NSLog(@"Image %@",_diaryPhoto.image);
    _diaryDetailTextView.text = _diaryData.diaryText;

    
    UIBarButtonItem *backupButton = [[UIBarButtonItem alloc]initWithTitle:@"Dropbox" style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(backupDiary)];
    
    backupButton.title = @"Dropbox";
    
    
    UIBarButtonItem *faceBookButton = [[UIBarButtonItem alloc]initWithTitle:@"Facebook" style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(shareDiary)];
    
    self.navigationItem.rightBarButtonItems = @[faceBookButton,backupButton];
}

- (void)shareDiary
{
    // We will post on behalf of the user, these are the permissions we need:
    //NSArray *permissionsNeeded = @[@"publish_actions"];
    //NSArray *permissionsNeeded = @[@"user_birthday",@"friends_hometown", @"friends_birthday",@"friends_location"];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Facebook"]) {
        [FacebookModel shareModel].diaryData = _diaryData;
        [[FacebookModel shareModel] ShareWithAPICalls:@[@"publish_actions"] action:kActionTypeSharePhoto requestPermissionType:kPermissionTypePublish];
    } else {
        [[FacebookModel shareModel] startFacebookSession];
    }
}

- (void)backupDiary
{
    if (!_diaryData.cloudRelationship.dropbox) {
        [[DropboxModel shareModel] linkToDropBox:^(BOOL linked) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[DropboxModel shareModel] uploadDiaryToFilesystem:_diaryData image:_diaryPhoto.image complete:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"uploadComplete" object:nil];
                }];
            });
        } fromController:self];
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
