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
        float sizeOffset = 14;
        self.backgroundColor = [UIColor whiteColor];
        self.opaque = YES;
        _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(sizeOffset/2,
                                                              1,
                                                              32,
                                                              32
                                                              )];
//        NSValue *rect = [NSValue valueWithCGRect:CGRectMake(sizeOffset/2,
//                                                            1,
//                                                            self.frame.size.width-sizeOffset,
//                                                            self.frame.size.width-sizeOffset
//                                                            )];
//        NSLog(@"Rect %@",rect);
        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
//        _dateLabel.layer.cornerRadius = _dateLabel.frame.size.width/2;
        [self addSubview:_dateLabel];
        _dateLabel.opaque = YES;
        _isToday = NO;
        _isSelected = NO;
    }
    return self;
}

-(void)addHasEventView
{
    UIView *hasEventView = [[UIView alloc]initWithFrame:CGRectMake(_dateLabel.center.x -self.frame.size.width/7-2,
                                                                   _dateLabel.frame.size.height+2,
                                                                   8,
                                                                   8)];
    
    hasEventView.layer.cornerRadius = hasEventView.frame.size.width/2;
    
    hasEventView.backgroundColor = [UIColor colorWithRed:1.000 green:0.827 blue:0.306 alpha:1.000];
    [self addSubview:hasEventView];
}

-(void)addHasDiaryView
{
    UIView *hasDiaryView = [[UIView alloc]initWithFrame:CGRectMake(_dateLabel.center.x +2,
                                                                   _dateLabel.frame.size.height+2,
                                                                   8,
                                                                   8)];
    
    hasDiaryView.layer.cornerRadius = hasDiaryView.frame.size.width/2;
    
    hasDiaryView.backgroundColor = Rgb2UIColor(41, 217, 194);
    [self addSubview:hasDiaryView];
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
