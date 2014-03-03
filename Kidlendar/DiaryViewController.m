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
#import <Social/Social.h>
//#import <Parse/Parse.h>

@interface DiaryViewController () <FBLoginViewDelegate>
{
    DropboxModel *DBModel;
    UIBarButtonItem *backupButton;
    UIBarButtonItem *shareButton;
}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetailTextView;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekdayLabel;
@property (weak, nonatomic) IBOutlet UIView *popUpBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *backupView;
@property (weak, nonatomic) IBOutlet UIView *shareView;
@property (weak, nonatomic) IBOutlet UIImageView *dropboxImageView;
@property (weak, nonatomic) IBOutlet UIImageView *twitterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weiboImageView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookImageView;

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
   _diaryDetailTextView.text = _diaryData.diaryText;
    _subjectLabel.text = _diaryData.subject;
    _locationLabel.text= _diaryData.location;
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:_diaryData.dateCreated];
    
    NSDateComponents *dateComp = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:diaryDate];
    
    NSArray *monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];

    NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
    
    _yearLabel.text = [NSString stringWithFormat:@"%ld",[dateComp year]];
    _monthLabel.text = [monthArray objectAtIndex: [dateComp month]-1];
    _dateLabel.text = [NSString stringWithFormat:@"%ld",[dateComp day]];
    _weekdayLabel.text  = [weekdayFormatter stringFromDate:diaryDate];
    
    UIBezierPath *exclusionPathYear = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_yearLabel.bounds
                                                                                                fromView:_yearLabel]];
    UIBezierPath *exclusionPathDate = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_dateLabel.bounds
                                                                                                fromView:_dateLabel]];
    UIBezierPath *exclusionPathMonth = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_monthLabel.bounds
                                                                                                 fromView:_monthLabel]];
    
    _diaryDetailTextView.textContainer.exclusionPaths = @[exclusionPathYear,exclusionPathDate,exclusionPathMonth];

    
    backupButton = [[UIBarButtonItem alloc]initWithTitle:@"Backup" style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(showBackup)];
    
    shareButton = [[UIBarButtonItem alloc]initWithTitle:@"Share" style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(showShare)];
    
    self.navigationItem.rightBarButtonItems = @[shareButton,backupButton];
    
    _backupView.layer.cornerRadius = 10.0f;
    _shareView.layer.cornerRadius = 10.0f;
    
    UITapGestureRecognizer *twitterTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_twitterImageView addGestureRecognizer:twitterTap];
    UITapGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_weiboImageView addGestureRecognizer:weiboTap];
    UITapGestureRecognizer *facebookTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_facebookImageView addGestureRecognizer:facebookTap];
}

- (IBAction)cancelPopup:(id)sender
{
    [self cancelAction];
}

- (void)cancelAction
{
    _popUpBackgroundView.hidden = YES;
    _shareView.hidden = YES;
    _backupView.hidden = YES;
    backupButton.enabled = YES;
    shareButton.enabled = YES;
    self.navigationItem.hidesBackButton = NO;
}

- (void)showBackup
{
    _popUpBackgroundView.hidden = NO;
    _shareView.hidden = YES;
    _backupView.hidden = NO;
    backupButton.enabled = NO;
    shareButton.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
}

- (void)showShare
{
    _popUpBackgroundView.hidden = NO;
    _backupView.hidden = YES;
    _shareView.hidden = NO;
    backupButton.enabled = NO;
    shareButton.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
}


- (void)shareDiary
{
    // We will post on behalf of the user, these are the permissions we need:
    //NSArray *permissionsNeeded = @[@"publish_actions"];
    //NSArray *permissionsNeeded = @[@"user_birthday",@"friends_hometown", @"friends_birthday",@"friends_location"];
    
//    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Facebook"]) {
//        [FacebookModel shareModel].diaryData = _diaryData;
//        [[FacebookModel shareModel] ShareWithAPICalls:@[@"publish_actions"] action:kActionTypeSharePhoto requestPermissionType:kPermissionTypePublish];
//    } else {
//        [[FacebookModel shareModel] startFacebookSession];
//    }
    
}

- (void)backupDiary
{
    if (!_diaryData.cloudRelationship.dropbox) {
        [[DropboxModel shareModel] linkToDropBox:^(BOOL linked) {
            if (linked) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[DropboxModel shareModel] uploadDiaryToFilesystem:_diaryData image:_diaryPhoto.image complete:^(BOOL success) {
                        
                    
                        
//                        PFPush *push = [[PFPush alloc] init];
//                        DBAccount *account = [[DBAccountManager sharedManager]linkedAccount];
//                        NSString *channelName = [NSString stringWithFormat:@"dropbox-%@",account.userId];
//                        NSArray *channel = @[channelName];
//                        NSString *userName = [[UIDevice currentDevice]name];
//                        NSString *message = [NSString stringWithFormat:@"%@ has uploaded new diary",userName];
//                        
//                        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
//                                              message, @"alert",
//                                              @"Increment", @"badge",
//                                              _diaryData.diaryKey, @"key",
//                                              nil];
//                        
//                        // Be sure to use the plural 'setChannels'.
//                        [push setChannels:channel];
//                        [push setData:data];
//                        [push sendPushInBackground];
                        if (success) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"uploadComplete" object:nil];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    }];
                });
            }
        } fromController:self];
    }
}

- (void)showShareSheet:(UITapGestureRecognizer *)sender
{
    [self cancelAction];

    NSString *serviceType;
    switch (sender.view.tag) {
        case 0:
            serviceType = SLServiceTypeTwitter;
            break;
        case 1:
            serviceType = SLServiceTypeSinaWeibo;
            break;
        case 2:
            serviceType = SLServiceTypeFacebook;
            break;
        default:
            break;
    }
    //  Create an instance of the share Sheet
    SLComposeViewController *shareSheet = [SLComposeViewController
                                           composeViewControllerForServiceType:
                                           serviceType]; // Service Type 有 Facebook/Twitter/微博 可以選
    
    shareSheet.completionHandler = ^(SLComposeViewControllerResult result) {
        switch(result) {
                //  This means the user cancelled without sending the Tweet
            case SLComposeViewControllerResultCancelled:
                break;
                //  This means the user hit 'Send'
            case SLComposeViewControllerResultDone:
                break;
        }
    };
    
    //  Set the initial body of the share sheet
    [shareSheet setInitialText:_diaryData.diaryText];
    
    //  分享照片
    if (![shareSheet addImage:_diaryData.diaryImage]) {
        NSLog(@"Unable to add the image!");
    }
    
    //  分享連結
//    if (![shareSheet addURL:[NSURL URLWithString:@"http://123.com/"]]){
//        NSLog(@"Unable to add the URL!");
//    }
    
    //  Presents the share Sheet to the user
    [self presentViewController:shareSheet animated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
