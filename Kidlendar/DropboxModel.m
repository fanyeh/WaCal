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

- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage complete:(void(^)(void))uploadComplete
{
    [self checkDiaryFolder:^{
        
        // Upload diary image to DBFilesystem
        NSString *uploadFilePath = [NSString stringWithFormat:@"%@/%@.png",folder,diary.diaryKey];
        DBPath *newPath = [[DBPath root] childPath:uploadFilePath];
        DBFile *file = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
        NSData *diaryImageData = UIImagePNGRepresentation(diaryImage);
        [file writeData:diaryImageData error:nil];
        
        // Upload diary text to DBFilesystem
        uploadFilePath = [NSString stringWithFormat:@"%@/%@.txt",folder,diary.diaryKey];
        newPath = [[DBPath root] childPath:uploadFilePath];
        file = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
        [file writeString:diary.diaryText error:nil];

        NSLog(@"file has successfully uploaded");
        diary.cloudRelationship.dropbox = YES;
        uploadComplete();
    }];
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

- (void)listUndownloadDiary:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    
    NSMutableArray *allDBfilesystemKeys = [[NSMutableArray alloc]init];
    NSMutableArray *allDiaryKeys = [[NSMutableArray alloc]init];
    
    // Get all available keys from DB filesystem
    for (DBFileInfo *info in listFiles) {
        NSString *fileExtension = [info.path.name pathExtension];
        if ([fileExtension isEqualToString:@"png"]) {
            NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
            [allDBfilesystemKeys addObject:diaryKey];
        }
    }
    
    // Get all diary keys in core data
    for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
        [allDiaryKeys addObject:d.diaryKey];
    }
   
    // Compare both array to get undownloaded keys
   [allDBfilesystemKeys removeObjectsInArray:allDiaryKeys];
    
    for (DBFileInfo *info in listFiles) {
        
        NSString *fileExtension = [info.path.name pathExtension];
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        
        if ([fileExtension isEqualToString:@"png"] && info.thumbExists && [allDBfilesystemKeys containsObject:diaryKey]) {
            
            DBFile *file = [filesystem openThumbnail:info.path ofSize:DBThumbSizeXS inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [file readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.thumbnail = diaryImage;
            t.thumbnailData = diaryImageData;
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    
    for (DBFileInfo *info in listFiles) {
        
        NSString *fileExtension = [info.path.name pathExtension];
        NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
        
        if ([fileExtension isEqualToString:@"txt"] && [allDBfilesystemKeys containsObject:diaryKey]) {
            TempDiaryData *t = [diarysFromCloud objectForKey:diaryKey];
            DBFile *file = [filesystem openFile:info.path error:nil];
            NSString *diaryText = [file readString:nil];
            NSLog(@"%@",diaryText);
            t.diaryText = diaryText;
        }
    }
    completeDownloadList(diarysFromCloud);
}



- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableDictionary *diarysFromCloud = [[NSMutableDictionary alloc]init];

    NSString *filePath = [NSString stringWithFormat:@"%@/",folder];
    DBPath *listFilePath = [[DBPath root] childPath:filePath];
    NSArray *listFiles = [filesystem listFolder:listFilePath error:nil];
    for (DBFileInfo *info in listFiles) {
        
        NSString *fileExtension = [info.path.name pathExtension];
        
        if ([fileExtension isEqualToString:@"png"]&info.thumbExists) {
            
            NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
            DBFile *file = [filesystem openThumbnail:info.path ofSize:DBThumbSizeXS inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [file readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            TempDiaryData *t = [[TempDiaryData alloc]init];
            t.diaryKey = diaryKey;
            t.thumbnail = diaryImage;
            t.thumbnailData = diaryImageData;
            [diarysFromCloud setObject:t forKey:diaryKey];
        }
    }
    for (DBFileInfo *info in listFiles) {
        
        NSString *fileExtension = [info.path.name pathExtension];

        if ([fileExtension isEqualToString:@"txt"]) {
            NSString *diaryKey = [info.path.name stringByDeletingPathExtension];
            TempDiaryData *t = [diarysFromCloud objectForKey:diaryKey];
            DBFile *file = [filesystem openFile:info.path error:nil];
            NSString *diaryText = [file readString:nil];
            NSLog(@"%@",diaryText);
            t.diaryText = diaryText;
        }
    }
    completeDownloadList(diarysFromCloud);
}

@end
