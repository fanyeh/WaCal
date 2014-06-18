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
        _selectedLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width/4, frame.size.height - 7 ,frame.size.width/2, 2)];
        _selectedLabel.layer.cornerRadius = 1;
        _selectedLabel.layer.masksToBounds = YES;
        _selectedLabel.hidden = YES;
        [self addSubview:_selectedLabel];
        
        self.dateLabel.textColor =  [UIColor colorWithWhite:0.298 alpha:1.000];
        self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        self.backgroundColor = [UIColor colorWithWhite:0.961 alpha:1.000];
        self.opaque = YES;
        self.lunarDateLabel.hidden = YES;
        
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
