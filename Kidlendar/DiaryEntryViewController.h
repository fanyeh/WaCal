//
//  DiaryEntryViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol DiaryDelegate <NSObject>
@optional
-(void )diaryDetails:(NSString *)details;
@end

@interface DiaryEntryViewController : UIViewController
{
    __weak id<DiaryDelegate>_delegate;
}
@property (nonatomic,weak)id<DiaryDelegate>delegate;

@end
