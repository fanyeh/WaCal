//
//  DiaryVideoViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface DiaryVideoViewController : UIViewController
@property (strong,nonatomic) NSURL *url;
@property (strong,nonatomic) ALAsset *asset;
@end
