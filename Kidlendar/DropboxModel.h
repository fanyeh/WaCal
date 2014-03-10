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
typedef void (^ListAllCloudDiarys)(NSMutableDictionary *diarysFromCloud);
typedef void (^DownloadBlock)(NSData *fileData);
typedef void (^UploadBlock)(BOOL success);

typedef NS_ENUM(NSInteger, SourceType)
{
    kSourceTypePhoto,
    kSourceTypeVideo,
    kSourceTypeAll
};


@interface DropboxModel : NSObject

@property (nonatomic,strong) DBDatastore *dataStore;;
@property (nonatomic,strong) UIViewController *observer;

+ (DropboxModel *)shareModel;

- (void)linkToDropBox:(LinkHandler)linkComplete fromController:(UIViewController *)controller;
- (void)setupFileSystemAndStore:(void(^)(BOOL))completeSetUp;
- (void)checkDiaryFolder:(void(^)(void))completeFolderCheck;
- (void)createFolder:(void(^)(void))completeFolderCreate;
- (void)uploadDiaryToFilesystem:(DiaryData *)diary mediaData:(NSData *)data mediaType:(SourceType)type complete:(UploadBlock)uploadComplete;
- (void)listAllCloudDiarys:(ListAllCloudDiarys)completeDownloadList;
- (void)downloadDiaryFromFilesystem:(NSString *)key  mediaType:(SourceType)type complete:(DownloadBlock)downloadComplete;

@end
