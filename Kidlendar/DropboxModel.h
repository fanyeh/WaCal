//
//  DropboxModel.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DBAccount;
@class DiaryData;
@class DBFilesystem;
@class DBDatastore;

typedef void (^LinkHandler)(BOOL linked);
typedef void (^ListAllCloudDiarys)(NSMutableArray *diarysFromCloud);
typedef void (^DownloadBlock)(NSData *imageData);

@interface DropboxModel : NSObject

@property (nonatomic,strong) DBDatastore *dataStore;;

+ (DropboxModel *)shareModel;

- (void)linkToDropBox:(LinkHandler)linkComplete fromController:(UIViewController *)controller;
- (void)setupFileSystemAndStore:(void(^)(BOOL))completeSetUp;
- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck;
- (void)createFolder:(void(^)(void))completeFolderCreate;
- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage complete:(void(^)(void))uploadComplete;
- (void)listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList;
- (void)listUndownloadDiary:(ListAllCloudDiarys)completeDownloadList;
- (void)downloadDiaryFromFilesystem:(NSString *)key complete:(DownloadBlock)downloadComplete;


- (void)createDiaryRecord:(NSString *)key diaryText:(NSString *)text;


@end
