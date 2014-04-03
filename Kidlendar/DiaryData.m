//
//  DiaryData.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/3.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryData.h"
#import "CloudData.h"


@implementation DiaryData

@dynamic dateCreated;
@dynamic diaryKey;
@dynamic diaryPhotoThumbnail;
@dynamic diaryPhotoThumbnailData;
@dynamic diaryText;
@dynamic diaryVideoData;
@dynamic diaryVideoPath;
@dynamic diaryVideoThumbData;
@dynamic diaryVideoThumbnail;
@dynamic location;
@dynamic orderingValue;
@dynamic subject;
@dynamic cloudRelationship;

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    NSTimeInterval t = [[NSDate date] timeIntervalSinceReferenceDate];
    [self setDateCreated:t];
}

- (void)setPhotoThumbnailDataFromImage:(UIImage *)image
{
    CGSize origImageSize = [image size];
    CGRect newRect = CGRectMake(0, 0, 90, 90); // thumbnail photo image size
    float ratio = MAX(newRect.size.width / origImageSize.width,
                      newRect.size.height / origImageSize.height);
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:newRect
                                                    cornerRadius:0.0];
    [path addClip];
    CGRect projectRect;
    projectRect.size.width = ratio * origImageSize.width;
    projectRect.size.height = ratio * origImageSize.height;
    projectRect.origin.x = (newRect.size.width - projectRect.size.width) / 2.0;
    projectRect.origin.y = (newRect.size.height - projectRect.size.height) / 2.0;
    [image drawInRect:projectRect];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    [self setDiaryPhotoThumbnail:smallImage];
    NSData *data = UIImagePNGRepresentation(smallImage);
    [self setDiaryPhotoThumbnailData:data];
    UIGraphicsEndImageContext();
}

- (void)setVideoThumbnailDataFromImage:(UIImage *)image
{
    CGSize origImageSize = [image size];
    CGRect newRect = CGRectMake(0, 0, 100, 100); // thumbnail photo image size
    float ratio = MAX(newRect.size.width / origImageSize.width,
                      newRect.size.height / origImageSize.height);
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:newRect
                                                    cornerRadius:0.0];
    [path addClip];
    CGRect projectRect;
    projectRect.size.width = ratio * origImageSize.width;
    projectRect.size.height = ratio * origImageSize.height;
    projectRect.origin.x = (newRect.size.width - projectRect.size.width) / 2.0;
    projectRect.origin.y = (newRect.size.height - projectRect.size.height) / 2.0;
    [image drawInRect:projectRect];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    [self setDiaryVideoThumbnail:smallImage];
    NSData *data = UIImagePNGRepresentation(smallImage);
    [self setDiaryVideoThumbData:data];
    UIGraphicsEndImageContext();
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    UIImage *pn = [UIImage imageWithData:[self diaryPhotoThumbnailData]];
    [self setPrimitiveValue:pn forKey:@"diaryPhotoThumbnail"];
    
    UIImage *vn = [UIImage imageWithData:[self diaryVideoThumbData]];
    [self setPrimitiveValue:vn forKey:@"diaryVideoThumbnail"];
    
}


@end
