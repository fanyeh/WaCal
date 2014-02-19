//
//  DiaryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryViewController.h"
#import "DiaryData.h"
#import "FileManager.h"
#import <FacebookSDK/FacebookSDK.h>
#import "KidlendarAppDelegate.h"
#import "DropboxModel.h"
#import <Dropbox/Dropbox.h>

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
    FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
    
    // Put that image onto the screen in our image view
    _diaryPhoto.image = [fm loadCollectionImage];
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

}

- (void)backupDiary
{
    [[DropboxModel shareModel] linkToDropBox:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[DropboxModel shareModel] uploadDiaryToFilesystem:_diaryData image:_diaryPhoto.image];
        });
    } fromController:self];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
