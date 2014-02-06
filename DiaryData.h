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
@property (nonatomic, retain) NSString * diaryText;
@property (nonatomic) double orderingValue;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic,strong) UIImage *thumbnail;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * diaryKey;

- (void)setThumbnailDataFromImage:(UIImage *)image;


@end
