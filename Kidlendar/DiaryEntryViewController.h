//
//  DiaryEntryViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiaryData.h"
#import "DiaryDataStore.h"

@interface DiaryEntryViewController : UIViewController
@property (strong,nonatomic) DiaryData *diary;
@end
