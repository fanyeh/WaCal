//
//  DiaryData.h
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/3.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CloudData;

@interface DiaryData : NSManagedObject

@property (nonatomic) NSTimeInterval dateCreated;
@property (nonatomic, retain) NSString * diaryKey;
@property (nonatomic, retain) UIImage *diaryPhotoThumbnail;
@property (nonatomic, retain) NSData * diaryPhotoThumbnailData;
@property (nonatomic, retain) NSString * diaryText;
@property (nonatomic, retain) NSData * diaryVideoData;
@property (nonatomic, retain) NSString * diaryVideoPath;
@property (nonatomic, retain) NSData * diaryVideoThumbData;
@property (nonatomic, retain) UIImage *diaryVideoThumbnail;
@property (nonatomic, retain) NSString * location;
@property (nonatomic) double orderingValue;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) CloudData *cloudRelationship;

- (void)setPhotoThumbnailDataFromImage:(UIImage *)image;
- (void)setVideoThumbnailDataFromImage:(UIImage *)image;


@end
