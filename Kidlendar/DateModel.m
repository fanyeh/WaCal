//
//  dateComponent.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/9.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DateModel.h"

@implementation DateModel

- (id)initWithDate:(NSDate *)date rowNumber:(int)row
{
    self = [super init];
    if(self) {
        _date  = date;
        _row = row;
        _isSelected = NO;
        _hasEvent = NO;
        _hasDiary = NO;
        _isToday = NO;
        _isCurrentMonth = NO;
        _isFirstDay = NO;
    }
    return self;
}

@end
