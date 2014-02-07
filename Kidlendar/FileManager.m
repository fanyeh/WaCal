//
//  FileManager.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/5.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "FileManager.h"

@implementation FileManager

- (id)initWithKey:(NSString *)key
{
    self = [super init];
    if (self)
    {
        paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths objectAtIndex:0];
        _fileDirectory = [documentsDirectory stringByAppendingPathComponent:key];
    }
    return self;
}

-(void)saveDiaryImage:(UIImage *)image index:(int)i
{
    fileName = [NSString stringWithFormat:@"diaryImage%d.png",i];
    savedImagePath = [_fileDirectory stringByAppendingPathComponent:fileName];
    imageData =  UIImagePNGRepresentation(image);
    [imageData writeToFile:savedImagePath atomically:NO];
}

-(UIImage *)loadDiaryImageWithIndex:(int)i
{
    fileName = [NSString stringWithFormat:@"diaryImage%d.png",i];
    NSString *getImagePath = [_fileDirectory stringByAppendingPathComponent:fileName];
    return  [UIImage imageWithContentsOfFile:getImagePath];
}


- (void)saveCollectionImage:(UIImage *)collectionViewImage
{
    savedImagePath = [_fileDirectory stringByAppendingPathComponent:@"collectionViewImage.png"];
    imageData =  UIImagePNGRepresentation(collectionViewImage);
    [imageData writeToFile:savedImagePath atomically:NO];
}

- (UIImage *)loadCollectionImage
{
    fileName = @"collectionViewImage.png";
    NSString *getImagePath = [_fileDirectory stringByAppendingPathComponent:fileName];
    return  [UIImage imageWithContentsOfFile:getImagePath];
}

@end
