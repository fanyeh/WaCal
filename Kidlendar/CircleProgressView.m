//
//  CircleProgressView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/23.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "CircleProgressView.h"

@implementation CircleProgressView {
    CGFloat startAngle;
    CGFloat endAngle;
    CAShapeLayer *circleLayer;
    CAShapeLayer *backgroundLayer;
}

- (id) initWithCoder:(NSCoder *)aCoder{
    if(self = [super initWithCoder:aCoder]) {
        // Initialization code
        //        self.backgroundColor = [UIColor whiteColor];
        
        // Determine our start and stop angles for the arc (in radians)
        startAngle = M_PI * 1.5;
        endAngle = startAngle + (M_PI * 2);
        circleLayer = [[CAShapeLayer alloc]init];
        backgroundLayer = [[CAShapeLayer alloc]init];
        [self.layer addSublayer:backgroundLayer];
        [self.layer addSublayer:circleLayer];
        [self setBackgroundPath];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

    }
    return self;
}

- (void)updateProgress:(float)progress
{
    CGMutablePathRef p1 = CGPathCreateMutable();
    CGPathAddArc(p1, nil, self.frame.size.width/2, self.frame.size.height/2, self.frame.size.width/2, startAngle, 2 * M_PI * progress + startAngle, NO);
    circleLayer.path = p1;
    CGPathRelease(p1);

    circleLayer.lineWidth = 3.0f;
    circleLayer.strokeColor = MainColor.CGColor;
    circleLayer.fillColor = [UIColor clearColor].CGColor;
}

-(void)setBackgroundPath
{
    CGMutablePathRef p2 = CGPathCreateMutable();
    CGPathAddArc(p2, nil, self.frame.size.width/2, self.frame.size.height/2, self.frame.size.width/2, startAngle, endAngle, NO);
    backgroundLayer.path = p2;
    CGPathRelease(p2);
    
    backgroundLayer.lineWidth = 3.0f;
    backgroundLayer.strokeColor = [UIColor colorWithWhite:0.902 alpha:1.000].CGColor;
    backgroundLayer.fillColor = [UIColor clearColor].CGColor;
}

@end
