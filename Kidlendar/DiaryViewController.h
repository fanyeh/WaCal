//
//  DiaryViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DiaryData;
@protocol diaryViewDelegate <NSObject>
@required
- (void)uploadProgress:(float)progress;
@end

@interface DiaryViewController : UIViewController
{
    __weak id<diaryViewDelegate>_delegate;
}
@property (weak,nonatomic) id<diaryViewDelegate>delegate;
@property (strong,nonatomic) DiaryData *diaryData;
//@property NSInteger index;

@end
