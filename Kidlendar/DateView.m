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
        labelSize = 29;
        dotSize = 6;
//        self.backgroundColor = [UIColor whiteColor];
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.frame.size.width - labelSize)/2,
                                                              1,
                                                              labelSize,
                                                              labelSize
                                                              )];

        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_dateLabel];
        _dateLabel.opaque = YES;
        _isToday = NO;
        _isSelected = NO;
        dotY = _dateLabel.frame.size.height+3;
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
    
    hasEventView.backgroundColor = Rgb2UIColor(242, 208, 59);
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
