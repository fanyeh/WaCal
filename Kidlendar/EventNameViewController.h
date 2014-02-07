//
//  EventNameViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EKEvent;

@interface EventNameViewController : UIViewController 
@property (strong,nonatomic) EKEvent *event;

@end
