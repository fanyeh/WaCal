//
//  DropboxModel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Dropbox/Dropbox.h>
#import "DropboxModel.h"
#import "FileManager.h"
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "FileManager.h"
#import "TempDiaryData.h"

@implementation DropboxModel
{
    DBDatastore *dataStore;
    
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
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    if (!account || !account.linked) {
        NSLog(@"No account linked\n");
        [[DBAccountManager sharedManager] linkFromController:controller];
    } else {
        NSLog(@"There's already DB account linked");
        [self setupFileSysteAndStore:account complete:linkComplete];
    }
}

- (void)setupFileSysteAndStore:(DBAccount *)account complete:(void(^)(void))completeSetUp
{
    DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
    [DBFilesystem setSharedFilesystem:filesystem];
    dataStore = [DBDatastore openDefaultStoreForAccount:account error:nil];
    completeSetUp();
}

- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage
{
    [self checkDiaryFolder:^{
        // Create new DBFile use diary key
        NSString *uploadFilePath = [NSString stringWithFormat:@"Diary/%@.png",diary.diaryKey];
        DBPath *newPath = [[DBPath root] childPath:uploadFilePath];
        DBFile *file = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
        
        DBFileStatus *status = file.status;
        if (!status.cached) {
            [file addObserver:self block:^() {
                // Check file.status and read if it's ready
                NSLog(@"Uploading progress %f", status.progress);
            }];
            // Check if the status.cached is now YES to ensure nothing
            // was missed while adding the observer
        }
        
        // Upload diary image to DBFilesystem
        NSData *diaryImageData = UIImagePNGRepresentation(diaryImage);
        [file writeData:diaryImageData error:nil];
        
        
        // Create new record in datastore
        [self createDiaryRecord:diary.diaryKey diaryText:diary.diaryText];
        NSLog(@"file has successfully uploaded");
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
    DBTable *diaryTable = [dataStore getTable:@"Diary"];
    [diaryTable insert:@{ @"diarykey": key, @"diarytext": text }];
    [dataStore sync:nil];
}

- (void)downloadDiaryFromFilesystem:(NSString *)key
{
    // Get datastore table
    DBTable *diaryTable = [dataStore getTable:@"Diary"];
    
    // Query record by key
    NSArray *results = [diaryTable query:@{@"diarykey": key} error:nil];
    
    if ([results count]==1) {
        DBRecord *r = [results objectAtIndex:0];
        
        NSString *newKey = [r objectForKey:@"diarykey"];
        NSString *newText = [r objectForKey:@"diarytext"];
        
        NSString *downloadFilePath = [NSString stringWithFormat:@"Diary/%@.png",newKey];
        DBPath *existingPath = [[DBPath root] childPath:downloadFilePath];
        DBFile *file = [[DBFilesystem sharedFilesystem] openFile:existingPath error:nil];
        NSData *diaryImageData = [file readData:nil];
        UIImage *diaryImage = [UIImage imageWithData:diaryImageData];
        DiaryData *downloadedDiary = [[DiaryDataStore sharedStore]createItem];
        downloadedDiary.diaryKey = newKey;
        downloadedDiary.diaryText = newText;
        [downloadedDiary setThumbnailDataFromImage:diaryImage];
        [[DiaryDataStore sharedStore]saveChanges];
        
        FileManager *fm = [[FileManager alloc]initWithKey:downloadedDiary.diaryKey];
        [fm saveCollectionImage:diaryImage];

    } else
        NSLog(@"Key not found or duplicate key of key %@",key);
}

- (NSMutableArray *)listUndownloadDiary
{
    NSMutableArray *undownloadDiarys = [[NSMutableArray alloc]init];
    
    // Get datastore table
    DBTable *diaryTable = [dataStore getTable:@"Diary"];
    
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
    
    // Get all data store keys from result
    for (DBRecord *r in results) {
        [dataStoreKeys addObject:[r objectForKey:@"diarykey"]];
    }
    
    // Get diary keys not on device
    [dataStoreKeys removeObjectsInArray:diaryKeysArray];
    
    
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
    return undownloadDiarys;
}



- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList
{
    NSMutableArray *diarysFromCloud = [[NSMutableArray alloc]init];
    
    // Get datastore table
    DBTable *diaryTable = [dataStore getTable:@"Diary"];
    NSLog(@"DBTable %@",diaryTable);
    
    // Get all diary keys from DB datastore
    NSMutableArray *dataStoreKeys = [[NSMutableArray alloc]init];
    NSMutableArray *dataStoreTexts = [[NSMutableArray alloc]init];
    
    // Query for all table's records
    NSArray *results = [diaryTable query:nil error:nil];
    
    // Get all data store keys from result
    for (DBRecord *r in results) {
        [dataStoreKeys addObject:[r objectForKey:@"diarykey"]];
        [dataStoreTexts addObject:[r objectForKey:@"diarytext"]];
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
        [diarysFromCloud addObject:tempDiaryData];
    }
    
    NSLog(@"Diarys from cloud %@",diarysFromCloud);

    
    completeDownloadList(diarysFromCloud);
}


@end
