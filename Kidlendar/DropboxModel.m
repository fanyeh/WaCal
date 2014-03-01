//
//  DropboxModel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "DropboxModel.h"
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "TempDiaryData.h"
#import "CloudData.h"
#import "LocationDataStore.h"
#import "LocationData.h"

@implementation DropboxModel
{
    DBFilesystem *filesystem;
    NSString *folder;
}

+ (DropboxModel *)shareModel
{
    static DropboxModel *shareModel = nil;
    if(!shareModel)
        shareModel = [[super allocWithZone:nil] init];
    
    return shareModel;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self shareModel];
}

- (id)init
{
    self = [super init];
    if(self) {
        folder = @"Diary";
    }
    return self;
}

- (void)linkToDropBox:(LinkHandler)linkComplete fromController:(UIViewController *)controller
{
    DBAccount  *account = [DBAccountManager sharedManager].linkedAccount;
    if (!account || !account.linked) {
        NSLog(@"No account linked\n");
        [[DBAccountManager sharedManager] linkFromController:controller];
        linkComplete(NO);
    } else {
        NSLog(@"There's already DB account linked");
        if ([DBFilesystem sharedFilesystem]) {
            NSLog(@"There's already DB filesystem linked");
            linkComplete(YES);
        }
        else {
            NSLog(@"Connect to filesystem");
            [self setupFileSystemAndStore:linkComplete];
        }
    }
}

- (void)setupFileSystemAndStore:(LinkHandler)completeSetUp
{
    filesystem = [[DBFilesystem alloc] initWithAccount:[DBAccountManager sharedManager].linkedAccount];
    [DBFilesystem setSharedFilesystem:filesystem];
    completeSetUp(YES);
}

- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage complete:(UploadBlock)uploadComplete
{
    if([self checkFile:diary.diaryKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Duplicate File"
                                                           message:@"You already have this diary on cloud"
                                                          delegate:self cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil, nil];
            [alert show];
        });
        uploadComplete(NO);
    } else {
        [self checkDiaryFolder:^{
            
            // Get diary location
            LocationData *diaryLocation = [[[LocationDataStore sharedStore]allItems]objectForKey:diary.diaryKey];
            NSDictionary *location;
            if (diaryLocation) {
                location = [[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%f",diaryLocation.latitude],@"latitude",[NSString stringWithFormat:@"%f",diaryLocation.longitude],@"longitude", nil];
            }
            
            // Create json dictionary
            NSString *diaryDate = [NSString stringWithFormat:@"%f",diary.dateCreated];
            NSDictionary *diaryDict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                       diary.subject,                                       @"diarySubject",
                                       diary.diaryText,                                     @"diaryText",
                                       diaryDate,                                           @"dateInterval",
                                       location,                                       @"diaryLocationCoordinate",
                                       diary.location,                                      @"diaryLocationName" ,
                                       nil];
            NSData *diaryData = [NSJSONSerialization dataWithJSONObject:diaryDict options:NSJSONWritingPrettyPrinted error:nil];
            
            // Upload diary image to DBFilesystem
            NSString *uploadImagePath = [NSString stringWithFormat:@"%@/%@.png",folder,diary.diaryKey];
            DBPath *newImagePath = [[DBPath root] childPath:uploadImagePath];
            DBFile *imageFile = [[DBFilesystem sharedFilesystem] createFile:newImagePath error:nil];
            NSData *diaryImageData = UIImagePNGRepresentation(diaryImage);
            [imageFile writeData:diaryImageData error:nil];
            
            // Upload diary text to DBFilesystem
            NSString *uploadDataPath = [NSString stringWithFormat:@"%@/%@.json",folder,diary.diaryKey];
            DBPath *newDataPath = [[DBPath root] childPath:uploadDataPath];
            DBFile *dataFile = [[DBFilesystem sharedFilesystem] createFile:newDataPath error:nil];
            [dataFile writeData:diaryData error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Upload Done"
                                                               message:@"You have successfully uploaded diary"
                                                              delegate:self cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil, nil];
                [alert show];
            });
            diary.cloudRelationship.dropbox = YES;
            uploadComplete(YES);
        }];
    }
}

- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck
{
    BOOL hasDiaryFolder = NO;
    NSArray *fileInfoArray = [[DBFilesystem sharedFilesystem]listFolder:[DBPath root] error:nil];
    for (DBFileInfo *fileInfo in fileInfoArray) {
        if (fileInfo.isFolder) {
            if ([fileInfo.path.name isEqualToString:folder])
                hasDiaryFolder = YES;
        }
    }
    if(!hasDiaryFolder) {
        [self createFolder:completeFolderCheck];
    } else {
        completeFolderCheck();
    }
}

- (void)createFolder:(void(^)(void))completeFolderCreate
{
    NSLog(@"Creating new folder");
    DBPath *newFolderPath = [[DBPath root] childPath:folder];
    NSLog(@"folder path %@", newFolderPath);
    DBError *error;
    if ([[DBFilesystem sharedFilesystem] createFolder:newFolderPath error:&error]) {
        NSLog(@"Create folder succeed");
        completeFolderCreate();
    }
    else {
        NSLog(@"Create folder failed with error :%@",error);
    }
}

- (void)downloadDiaryFromFilesystem:(NSString *)key  complete:(DownloadBlock)downloadComplete
{
    NSString *downloadFilePath = [NSString stringWithFormat:@"%@/%@.png",folder,key];
    DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
    NSData *diaryImageData = [file readData:nil];
    
    downloadComplete(diaryImageData);
}

- (BOOL)checkFile:(NSString *)key
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png",folder,key];
    DBPath *existingPath = [[DBPath root] childPath:filePath];
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
    if (file) {
        return YES;
    } else {
        return NO;
    }
}

- (void)listUndownloadDiary:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    
    NSMutableArray *allDiaryKeys = [[NSMutableArray alloc]init];
    
    // Get all diary keys in core data
    for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
        [allDiaryKeys addObject:d.diaryKey];
    }
    
    // Get all available keys from DB filesystem
    for (DBFileInfo *info in listFiles) {
        
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        NSString *fileExtension = [info.path.name pathExtension];

        if ([fileExtension isEqualToString:@"png"] && info.thumbExists && ![allDiaryKeys containsObject:diaryKey]) {
            
            // Get diary image thumbnail
            DBFile *imageFile = [filesystem openThumbnail:info.path ofSize:DBThumbSizeXS inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [imageFile readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];

            // Get diary json
            NSString *diaryDataPath = [NSString stringWithFormat:@"%@/%@.json",folder,diaryKey];
            DBPath *existingPath = [[DBPath root] childPath:diaryDataPath];
            DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
            
            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.thumbnail = diaryImage;
            NSData *json = [dataFile readData:nil];
            t.diaryData = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingAllowFragments error:nil];
            
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    completeDownloadList(diarysFromCloud);
}

- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList
{
    NSLog(@"list all diary");
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];

    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    NSLog(@"List %@",listFiles);
    // Get all available keys from DB filesystem
    for (DBFileInfo *info in listFiles) {
        
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        NSString *fileExtension = [info.path.name pathExtension];
        
        
        if ([fileExtension isEqualToString:@"png"] && info.thumbExists) {
            
            // Get diary image thumbnail
            DBFile *imageFile = [filesystem openThumbnail:info.path ofSize:DBThumbSizeM inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [imageFile readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            
            // Get diary json
            NSString *diaryDataPath = [NSString stringWithFormat:@"%@/%@.json",folder,diaryKey];
            DBPath *existingPath = [[DBPath root] childPath:diaryDataPath];
            DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
            
            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.thumbnail = diaryImage;
            NSData *json = [dataFile readData:nil];
            t.diaryData = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingAllowFragments error:nil];
            
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    completeDownloadList(diarysFromCloud);
}

@end
