//
//  CustomTextField.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/16.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "CustomTextField.h"

@implementation CustomTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 150, 20)];
        _dateLabel.font = [UIFont fontWithName:@"Avenir-Light" size:15];
        self.font = [UIFont fontWithName:@"Avenir-Light" size:25];
        [self addSubview:_dateLabel];
    }
    return self;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
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
