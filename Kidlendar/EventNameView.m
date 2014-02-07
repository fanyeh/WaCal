//
//  EventNameView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventNameView.h"

@implementation EventNameView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _backgroundImageView = [[UIImageView alloc]initWithFrame:frame];
        [_backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
        [self addSubview:_backgroundImageView];
        
        _nameField = [[UITextField alloc]initWithFrame:CGRectMake(10, 77, 300, 50)];
        _nameField.backgroundColor =  [UIColor colorWithWhite:0.8 alpha:0.8];
        _nameField.placeholder = @"Who?";
        _nameField.font = [UIFont fontWithName:@"Avenir-Light" size:25];
        [self addSubview:_nameField];
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
