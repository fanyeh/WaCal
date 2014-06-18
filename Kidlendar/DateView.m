//
//  customLabel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DateView.h"
#import "DateModel.h"

@implementation DateView
{
    float labelSize;
    float dotSize;
    float dotY;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        labelSize = 25;
        dotSize = 6;
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.frame.size.width - labelSize)/2,
                                                              1,
                                                              labelSize,
                                                              labelSize
                                                              )];

        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_dateLabel];
        
        
        _lunarDateLabel  =  [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                             27,
                                                                             self.frame.size.width,
                                                                             10
                                                                             )];
        _lunarDateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:9];
        _lunarDateLabel.textAlignment = NSTextAlignmentCenter;
        _lunarDateLabel.text = @"初一";
        _lunarDateLabel.textColor = LightGrayColor;
        //lunarDateLabel.layer.borderWidth = 0.5;
        [self addSubview:_lunarDateLabel];
        
        _dateLabel.opaque = YES;
        _isToday = NO;
        _isSelected = NO;
        dotY = self.frame.size.height - 1 - dotSize;
    }
    return self;
}

-(void)addHasEventView
{
    UIView *hasEventView = [[UIView alloc]initWithFrame:CGRectMake(_dateLabel.center.x - dotSize - 3,
                                                                   dotY,
                                                                   dotSize,
                                                                   dotSize)];
    
    hasEventView.layer.cornerRadius = hasEventView.frame.size.width/2;
    
    hasEventView.backgroundColor = [UIColor lightGrayColor];

    [self addSubview:hasEventView];
}

-(void)addHasDiaryView
{
    UIView *hasDiaryView = [[UIView alloc]initWithFrame:CGRectMake(_dateLabel.center.x + 3,
                                                                   dotY,
                                                                   dotSize,
                                                                   dotSize)];
    
    hasDiaryView.layer.cornerRadius = hasDiaryView.frame.size.width/2;
    
    hasDiaryView.backgroundColor = MainColor;
    [self addSubview:hasDiaryView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _dateLabel.layer.cornerRadius = _dateLabel.frame.size.width/2;
}

@end
