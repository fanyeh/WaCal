//
//  BackupViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "BackupViewController.h"

@interface BackupViewController () <DBRestClientDelegate>

@end

@implementation BackupViewController

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
}
- (IBAction)linkToDropBox:(id)sender
{
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] linkFromController:self];
    } else {
        [[DBSession sharedSession] unlinkAll];
        [[[UIAlertView alloc] initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}
- (IBAction)createFolder:(id)sender
{
    // Create New folder command
    [[self restClient] createFolder:@"/TestFolder"];
}
- (IBAction)uploadFile:(id)sender
{
    //NSString *localPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSString *filename = @"test.txt";
    NSString *destDir = @"/TestFolder";
    [[self restClient] uploadFile:filename toPath:destDir
                    withParentRev:nil fromPath:nil];
}
- (IBAction)checkFolders:(id)sender
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
        for (DBMetadata *file in metadata.contents) {
            if (file.isDirectory) {
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
