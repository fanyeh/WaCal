//
//  DiaryViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DiaryData;

@interface DiaryViewController : UIViewController
@property (strong,nonatomic) DiaryData *diaryData;
@property NSInteger index;
@end
