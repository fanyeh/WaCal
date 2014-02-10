//
//  DiaryData.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/30.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DiaryData : NSManagedObject

@property (nonatomic) NSTimeInterval dateCreated;
@property (nonatomic, strong) NSString * diaryText;
@property (nonatomic) double orderingValue;
@property (nonatomic, strong) NSString * subject;
@property (nonatomic,strong) UIImage *thumbnail;
@property (nonatomic, strong) NSData * thumbnailData;
@property (nonatomic, strong) NSString * diaryKey;

- (void)setThumbnailDataFromImage:(UIImage *)image;

@end
