//
//  CloudData.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/19.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiaryData;

@interface CloudData : NSManagedObject

@property (nonatomic) BOOL icloud;
@property (nonatomic) BOOL baidu;
@property (nonatomic) BOOL googledrive;
@property (nonatomic) BOOL dropbox;
@property (nonatomic, retain) DiaryData *diaryRelationship;

@end
