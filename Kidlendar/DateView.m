//
//  customLabel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DateView.h"
#import "DateModel.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

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
        self.backgroundColor = [UIColor whiteColor];
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake((self.frame.size.width - labelSize)/2,
                                                              1,
                                                              labelSize,
                                                              labelSize
                                                              )];

        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:19];
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
    
    hasEventView.backgroundColor = [UIColor colorWithRed:1.000 green:0.827 blue:0.306 alpha:1.000];
    [self addSubview:hasEventView];
}

-(void)addHasDiaryView
{
    UIView *hasDiaryView = [[UIView alloc]initWithFrame:CGRectMake(_dateLabel.center.x + 3,
                                                                   dotY,
                                                                   dotSize,
                                                                   dotSize)];
    
    hasDiaryView.layer.cornerRadius = hasDiaryView.frame.size.width/2;
    
    hasDiaryView.backgroundColor = Rgb2UIColor(41, 217, 194);
    [self addSubview:hasDiaryView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _dateLabel.layer.cornerRadius = _dateLabel.frame.size.width/2;
}

@end
