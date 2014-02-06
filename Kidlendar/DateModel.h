//
//  dateComponent.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/9.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateModel : NSObject
@property (strong,nonatomic) NSDate *date;
@property int row;
@property BOOL isSelected;
@property BOOL hasEvent;
@property BOOL hasDiary;
@property BOOL isToday;
@property BOOL isCurrentMonth;
@property BOOL isFirstDay;

- (id)initWithDate:(NSDate *)date rowNumber:(int)row;

@end
