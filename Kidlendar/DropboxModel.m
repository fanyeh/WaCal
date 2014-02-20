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
    
    if (!_dataStore) {
        _dataStore = [DBDatastore openDefaultStoreForAccount:[DBAccountManager sharedManager].linkedAccount error:nil];
    }
    [_dataStore sync:nil];
    completeSetUp(YES);
}

- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage complete:(void(^)(void))uploadComplete
{
    [self checkDiaryFolder:^{
        
        // Create new DBFile use diary key
        NSString *uploadFilePath = [NSString stringWithFormat:@"Diary/%@.png",diary.diaryKey];
        DBPath *newPath = [[DBPath root] childPath:uploadFilePath];
        DBFile *file = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
            
        // Upload diary image to DBFilesystem
        NSData *diaryImageData = UIImagePNGRepresentation(diaryImage);
        [file writeData:diaryImageData error:nil];
        
        
        // Create new record in datastore
        [self createDiaryRecord:diary.diaryKey diaryText:diary.diaryText];
        NSLog(@"file has successfully uploaded");
        
        diary.cloudRelationship.dropbox = YES;
        [[DiaryDataStore sharedStore]saveChanges];
        uploadComplete();
    }];
}

- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck
{
    BOOL hasDiaryFolder = NO;
    NSArray *fileInfoArray = [[DBFilesystem sharedFilesystem]listFolder:[DBPath root] error:nil];
    for (DBFileInfo *fileInfo in fileInfoArray) {
        if (fileInfo.isFolder) {
            if ([fileInfo.path.name isEqualToString:@"Diary"])
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
    DBPath *newFolderPath = [[DBPath root] childPath:@"Diary"];
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

- (void)createDiaryRecord:(NSString *)key diaryText:(NSString *)text
{
    DBTable *diaryTable = [_dataStore getTable:@"Diary"];
    [diaryTable insert:@{ @"diarykey": key, @"diarytext": text }];
    [_dataStore sync:nil];
}

- (void)downloadDiaryFromFilesystem:(NSString *)key  complete:(DownloadBlock)downloadComplete
{
    // Get datastore table
    DBTable *diaryTable = [_dataStore getTable:@"Diary"];
    
    // Query record by key
    NSArray *results = [diaryTable query:@{@"diarykey": key} error:nil];
    NSLog(@"Result %@",results);
    
    if ([results count]>0) {
        NSString *downloadFilePath = [NSString stringWithFormat:@"Diary/%@.png",key];
        DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
        DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
        
        NSData *diaryImageData = [file readData:nil];
        
        downloadComplete(diaryImageData);
    } else
        NSLog(@"Key not found or duplicate key of key %@",key);
}

- (void)listUndownloadDiary:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableArray *undownloadDiarys = [[NSMutableArray alloc]init];
    
    // Get datastore table
    DBTable *diaryTable = [_dataStore getTable:@"Diary"];
    NSLog(@"DBTable %@",diaryTable);
    
    // Get all diary keys from core data
    NSMutableArray *diaryKeysArray = [[NSMutableArray alloc]init];
    for (DiaryData *d in [[DiaryDataStore sharedStore]allItems]) {
        [diaryKeysArray addObject:d.diaryKey];
    }
    
    // Get all diary keys from DB datastore
    NSMutableArray *dataStoreKeys = [[NSMutableArray alloc]init];
    NSMutableArray *dataStoreTexts = [[NSMutableArray alloc]init];
    
    // Query for all table's records
    NSArray *results = [diaryTable query:nil error:nil];
    NSLog(@"query result %@",results);
    
    // Get all data store keys from result
    for (DBRecord *r in results) {
        [dataStoreKeys addObject:[r objectForKey:@"diarykey"]];
    }
    
    NSLog(@"Data store keys %@",dataStoreKeys);

    
    // Get diary keys not on device
    [dataStoreKeys removeObjectsInArray:diaryKeysArray];
    
    NSLog(@"Data store keys after compare %@",dataStoreKeys);

    // If other key exists , download the diary
    if ([dataStoreKeys count]>0) {
        
        for (NSString *key in dataStoreKeys) {
            NSArray *undownloadDiary = [diaryTable query:@{@"diarykey": key} error:nil];
            if ([undownloadDiary count]==1) {
                DBRecord *r = [undownloadDiary objectAtIndex:0];
                [dataStoreTexts addObject:[r objectForKey:@"diarytext"]];
            } else
                NSLog(@"Key not found or duplicate key of key %@",key);
        }
        
        for (int i = 0 ; i < [dataStoreKeys count];i++) {
            NSString *downloadFilePath = [NSString stringWithFormat:@"Diary/%@.png",[dataStoreKeys objectAtIndex:i]];
            DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
            DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
            NSData *diaryImageData = [file readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            TempDiaryData *tempDiaryData = [[TempDiaryData alloc]init];
            tempDiaryData.diaryKey = [dataStoreKeys objectAtIndex:i];
            tempDiaryData.diaryText = [dataStoreTexts objectAtIndex:i];
            [tempDiaryData setThumbnailDataFromImage:diaryImage];
            [undownloadDiarys addObject:tempDiaryData];
        }
    }
    completeDownloadList(undownloadDiarys);
}



- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableArray *diarysFromCloud = [[NSMutableArray alloc]init];
    
    if (_dataStore.isOpen) {
        NSLog(@"DS is open");
    }
    
    DBTable *diaryTable = [_dataStore getTable:@"Diary"];
    NSLog(@"Table ID %@",diaryTable.tableId);
    
    // Get all diary keys from DB datastore
    NSMutableArray *dataStoreKeys = [[NSMutableArray alloc]init];
    NSMutableArray *dataStoreTexts = [[NSMutableArray alloc]init];
    
    // Query for all table's records
    NSArray *results = [diaryTable query:nil error:nil];
    
    NSLog(@"results %@",results);
    
    // Get all data store keys from result
    for (DBRecord *r in results) {
        [dataStoreKeys addObject:[r objectForKey:@"diarykey"]];
        [dataStoreTexts addObject:[r objectForKey:@"diarytext"]];
    }
    
    for (int i = 0 ; i < [dataStoreKeys count];i++) {
        NSString *downloadFilePath = [NSString stringWithFormat:@"Diary/%@.png",[dataStoreKeys objectAtIndex:i]];
        DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
        DBFileInfo *fileInfo = [filesystem fileInfoForPath:existingPath error:nil];
        
        if (fileInfo.thumbExists) {
            DBFile *file = [[DBFilesystem sharedFilesystem] openThumbnail:existingPath ofSize:DBThumbSizeXS inFormat:DBThumbFormatPNG error:nil];
            NSData *diaryImageData = [file readData:nil];
            UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
            TempDiaryData *tempDiaryData = [[TempDiaryData alloc]init];
            tempDiaryData.diaryKey = [dataStoreKeys objectAtIndex:i];
            tempDiaryData.diaryText = [dataStoreTexts objectAtIndex:i];
            tempDiaryData.thumbnail = diaryImage;
            tempDiaryData.thumbnailData = diaryImageData;
            [diarysFromCloud addObject:tempDiaryData];
        }
    }
    completeDownloadList(diarysFromCloud);
}

@end
