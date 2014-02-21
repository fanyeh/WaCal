//
//  FacebookModel.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DiaryData;

typedef NS_ENUM(NSInteger, PermissionType)
{
    kPermissionTypeRead,
    kPermissionTypePublish
};

typedef NS_ENUM(NSInteger, ActionType)
{
    kActionTypeShareLink,
    kActionTypeSharePhoto,
    kActionTypeFriendsBirthday
};

@interface FacebookModel : NSObject

+ (FacebookModel *)shareModel;

@property (nonatomic,strong) DiaryData *diaryData;

- (void)startFacebookSession;
- (void)ShareWithAPICalls:(NSArray *)permissionsNeeded action:(ActionType)actionType requestPermissionType:(PermissionType)permissionType;

@end
