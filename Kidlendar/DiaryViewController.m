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
#import <DropboxSDK/DropboxSDK.h>

@interface DiaryViewController () <DBRestClientDelegate>
{
    BOOL folderExist;
    NSString *foldername;
    
}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UILabel *diarySubject;
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
    
    // Extend view from navigation bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Get photo from  use diary data key
    FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
    
    // Put that image onto the screen in our image view
    _diaryPhoto.image = [fm loadCollectionImage];
    _diarySubject.text = _diaryData.subject;
    
    UIBarButtonItem *backupButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                                 target:self
                                                                                 action:@selector(backupDiary)];
    
    self.navigationItem.rightBarButtonItem = backupButton;

    
    // TODO:Add swipe gesture , only swipable if there are more than 1 diaries
    // TODO:Add share button on navigation bar right
}

- (void)backupDiary
{
    [self linkToDropBox];
    // Diary file system structure should be "/kidlendar/profile name/create date time - diary title/filename"
}

- (void)linkToDropBox
{
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:self];
        // Call method to execute folder check with completion block
        [self checkFolders:^{
            NSString *subfolder = [NSString stringWithFormat:@"%f-%@",_diaryData.dateCreated,_diaryData.subject];
            foldername  = @"unknown";
            FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
            NSString *fromDir = [fm fileDirectory];
            NSString *filename = @"collectionViewImage.png";
            if (folderExist) {
                // save file
                NSString *destDir = [NSString stringWithFormat:@"/%@/%@",foldername,subfolder];
                
                [_restClient uploadFile:filename
                                 toPath:destDir
                          withParentRev:nil
                               fromPath:fromDir];
            }
            else {
                // create folder then save file
                [self createFolderName:foldername completion:^{
                    
                    NSString *destDir = [NSString stringWithFormat:@"/%@/%@",foldername,subfolder];
                    
                    [_restClient uploadFile:filename
                                     toPath:destDir
                              withParentRev:nil
                                   fromPath:fromDir];
                }];
            }
        }];
    } else {
        [[DBSession sharedSession] unlinkAll];
        [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}
- (void)createFolderName:(NSString *)name completion:(void(^)())block
{
    // Create New folder command
    NSString *folder = [NSString stringWithFormat:@"/%@",name];
    [[self restClient] createFolder:folder];
}

- (void)checkFolders:(void(^)())block
{
    [[self restClient] loadMetadata:@"/"];
}

#pragma mark - DBRestClientDelegate
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {
        NSLog(@"Folder '%@' contains:", metadata.path);
        folderExist = NO;
        for (DBMetadata *file in metadata.contents) {
            if (file.isDirectory && [file.filename isEqualToString:foldername]) {
                folderExist = YES;
                break;
                // compare file.filename with profile name , if not exist create new folder use profile name
                // if there's no profile name , create new forder named "unknown"
                // Diary file system structure should be "/kidlendar/profile name/create date time - diary title/filename"
            }
        }
    }
}

- (void)restClient:(DBRestClient *)clientloadMetadata FailedWithError:(NSError *)error {
    
    NSLog(@"Error loading metadata: %@", error);
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
