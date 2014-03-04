//
//  DiaryEntryViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MediaType)
{
    kMediaTypePhoto,
    kMediaTypeVideo
};


@class ALAsset;

@interface DiaryEntryViewController : UIViewController
@property (strong,nonatomic) UIImage *diaryImage;
@property (strong,nonatomic) NSMutableArray *imageMeta;
@property (strong,nonatomic) ALAsset *asset;
@property MediaType selectedMediaType;

@end
