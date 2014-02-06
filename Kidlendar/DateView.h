//
//  customLabel.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DateView : UIView
@property (strong,nonatomic) UILabel *dateLabel;
@property (strong,nonatomic) NSDate *date;
@property int row;
@property BOOL isSelected;
@property BOOL isToday;
@property BOOL hasEvent;
@property BOOL hasDiary;

- (void)addHasEventView;
@end
