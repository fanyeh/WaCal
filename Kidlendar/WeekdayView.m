//
//  WeekdayView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/25.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "WeekdayView.h"

@implementation WeekdayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        CGFloat labelX = frame.size.width/2 - frame.size.width/4;
        _selectedLabel = [[UILabel alloc]initWithFrame:CGRectMake(labelX, frame.size.height - 12 ,frame.size.width/2, 3)];
        _selectedLabel.layer.cornerRadius = 1.5f;
        _selectedLabel.hidden = YES;
        [self addSubview:_selectedLabel];
        
        self.dateLabel.textColor =  [UIColor colorWithWhite:0.298 alpha:1.000];
        self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
        self.backgroundColor = [UIColor whiteColor];
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
