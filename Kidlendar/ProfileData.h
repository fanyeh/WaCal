//
//  ProfileData.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/30.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiaryData;

@interface ProfileData : NSManagedObject

@property (nonatomic) NSTimeInterval birthDate;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * imageKey;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) double orderingValue;
@property (nonatomic,strong) UIImage *thumbnail;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSSet *diarys;
@end

@interface ProfileData (CoreDataGeneratedAccessors)

- (void)setThumbnailDataFromImage:(UIImage *)image;
- (void)addDiarysObject:(DiaryData *)value;
- (void)removeDiarysObject:(DiaryData *)value;
- (void)addDiarys:(NSSet *)values;
- (void)removeDiarys:(NSSet *)values;

@end
