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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        float sizeOffset = 13;
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(sizeOffset/2,
                                                              sizeOffset/2,
                                                              self.frame.size.width-sizeOffset,
                                                              self.frame.size.width-sizeOffset
                                                              )];
        _dateLabel.font = [UIFont fontWithName:@"Avenir-Light" size:25];
        _dateLabel.textColor = Rgb2UIColor(255, 255, 255);
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_dateLabel];
        _isToday = NO;
        _isSelected = NO;
    }
    return self;
}

-(void)addHasEventView
{
    UIView *hasEventView = [[UIView alloc]initWithFrame:CGRectMake(self.frame.size.width/8*3,
                                                                   self.frame.size.width-5,
                                                                   self.frame.size.width/4,
                                                                   self.frame.size.height/15)];
    hasEventView.backgroundColor = [UIColor grayColor];
    [self addSubview:hasEventView];
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
