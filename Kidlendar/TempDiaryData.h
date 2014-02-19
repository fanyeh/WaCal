//
//  TempDiaryData.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TempDiaryData : NSObject
@property (nonatomic) NSTimeInterval dateCreated;
@property (nonatomic, strong) NSString * diaryText;
@property (nonatomic) double orderingValue;
@property (nonatomic, strong) NSString * subject;
@property (nonatomic,strong) UIImage *thumbnail;
@property (nonatomic, strong) NSData * thumbnailData;
@property (nonatomic, strong) NSString * diaryKey;

- (void)setThumbnailDataFromImage:(UIImage *)image;
@end
