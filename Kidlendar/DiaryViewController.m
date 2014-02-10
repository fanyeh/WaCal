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
    BOOL subFolderExist;
    NSString *foldername;
    NSString *subfolderName;
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
    
    UIBarButtonItem *backupButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                                 target:self
                                                                                 action:@selector(backupDiary)];
    
    self.navigationItem.rightBarButtonItem = backupButton;
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(uploadFile:)
                                                name:@"folderCheckDone" object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(uploadFile:)
                                                name:@"folderCreateDone" object:nil];


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
    }
    else {
        foldername  = @"unknown";
        [[self restClient] loadMetadata:@"/"];

//        [[DBSession sharedSession] unlinkAll];
//        [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked"
//                                   delegate:nil
//                          cancelButtonTitle:@"OK"
//                          otherButtonTitles:nil] show];
    }
}

- (void)uploadFile:(NSNotification *)notification
{
    NSLog(@"Checking folders");
    subfolderName = [NSString stringWithFormat:@"%f",_diaryData.dateCreated];
    FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
    NSString *fromDir = [fm fileDirectory];
    NSString *filename = @"collectionViewImage.png";
    
    if (folderExist) {
        if (subFolderExist) {
            // save file
            NSString *destDir = [NSString stringWithFormat:@"/%@/%@",foldername,subfolderName];
            [_restClient uploadFile:filename
                             toPath:destDir
                      withParentRev:nil
                           fromPath:fromDir];
        }
        else {
            [[self restClient] createFolder:[NSString stringWithFormat:@"/%@/%@",foldername,subfolderName]];
        }
    }
    else {
        // create folder then save file
        [[self restClient] createFolder:foldername];
    }
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
        folderExist = NO;
        subFolderExist = NO;
        for (DBMetadata *file in metadata.contents) {
            // Check if there's folder
            if (file.isDirectory && [file.filename isEqualToString:foldername]) {
                folderExist = YES;
                NSLog(@"Folder %@",file.filename);
                NSLog(@"Contents %@",file.contents);
                for (DBMetadata *subFolder in file.contents) {
                    // Check if there's subfolder
                    NSLog(@"Sub folder %@",subFolder.filename);
                    if (subFolder.isDirectory && [subFolder.filename isEqualToString:subfolderName]) {
                        subFolderExist = YES;
                        break;
                    }
                }
                break;
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"folderCheckDone" object:nil];
    }
    // compare file.filename with profile name , if not exist create new folder use profile name
    // if there's no profile name , create new forder named "unknown"
    // Diary file system structure should be "/kidlendar/profile name/create date time - diary title/filename"
}

- (void)restClient:(DBRestClient *)clientloadMetadata FailedWithError:(NSError *)error {
    
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient*)client createdFolder:(DBMetadata*)folder;
{
    // Folder is the metadata for the newly created folder
    [[NSNotificationCenter defaultCenter] postNotificationName:@"folderCreateDone" object:nil];
}

- (void)restClient:(DBRestClient*)client createFolderFailedWithError:(NSError*)error;
{
    NSLog(@"Error create folder: %@", error);
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
