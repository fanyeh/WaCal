//
//  DropboxModel.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DiaryData;

@interface DropboxModel : NSObject
@property (nonatomic,strong) DiaryData *diaryData;

+ (DropboxModel *)shareModel;

- (void)linkToDropBox:(UIViewController *)controller;
- (void)createFolder;

- (void)createDiaryRecord:(NSString *)key diaryText:(NSString *)text;
- (BOOL)checkDiaryFolder;


@end
