//
//  EventTitleView.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/15.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomTextField.h"

@interface EventTitleAndTimeView : UIView
@property (strong,nonatomic) UITextField *titleField;
@property (strong,nonatomic) CustomTextField *startTimeField;
@property (strong,nonatomic) CustomTextField *endTimeField;
@property (strong,nonatomic) UIButton *saveButton;
@property (strong,nonatomic) UIButton *allDayButton;

@end
