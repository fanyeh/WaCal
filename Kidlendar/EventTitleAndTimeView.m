//
//  EventTitleView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/15.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventTitleAndTimeView.h"

@implementation EventTitleAndTimeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _titleField = [[UITextField alloc]initWithFrame:CGRectMake(10, 72, 300, 50)];
        _titleField.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
        _titleField.placeholder = @"Please enter title";
        _titleField.tag = 0;
        _titleField.font = [UIFont fontWithName:@"Avenir-Light" size:25];
        
        _startTimeField = [[CustomTextField alloc]initWithFrame:CGRectMake(10, 137, 145, 50)];
        _startTimeField.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
        _startTimeField.tag = 1;
        _startTimeField.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        
        _endTimeField = [[CustomTextField alloc]initWithFrame:CGRectMake(165,137, 145, 50)];
        _endTimeField.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
        _endTimeField.tag = 2;
        _endTimeField.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        
        _saveButton = [[UIButton alloc]initWithFrame:CGRectMake(240, 202, 70, 50)];
        _saveButton.backgroundColor = [UIColor greenColor];
        _saveButton.titleLabel.textColor = [UIColor whiteColor];
        [_saveButton setTitle:@"Save" forState:UIControlStateNormal];
        
        _allDayButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 202, 70, 50)];
        _allDayButton.backgroundColor = [UIColor yellowColor];
        _allDayButton.titleLabel.textColor = [UIColor whiteColor];
        [_allDayButton setTitle:@"AllDay" forState:UIControlStateNormal];
        
        [self addSubview:_startTimeField];
        [self addSubview:_endTimeField];
        [self addSubview:_titleField];
        [self addSubview:_saveButton];
        [self addSubview:_allDayButton];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
