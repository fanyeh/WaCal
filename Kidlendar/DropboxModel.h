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

typedef void (^LinkHandler)(void);
typedef void (^ListAllCloudDiarys)(NSMutableArray *diarysFromCloud);


@interface DropboxModel : NSObject

+ (DropboxModel *)shareModel;

- (void)linkToDropBox:(LinkHandler)linkComplete fromController:(UIViewController *)controller;
- (void)setupFileSysteAndStore:(DBAccount *)account complete:(void(^)(void))completeSetUp;
- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck;
- (void)createFolder:(void(^)(void))completeFolderCreate;
- (void)uploadDiaryToFilesystem:(DiaryData *)diary image:(UIImage *)diaryImage;
- (void )listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList;


- (void)createDiaryRecord:(NSString *)key diaryText:(NSString *)text;


@end
