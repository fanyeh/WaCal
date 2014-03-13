//
//  Repeat.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "RepeatView.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@implementation RepeatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init {
    self = [super initWithFrame:CGRectMake(0,568, 320, 216)];
    if (self) {
        // Initialization code
        
        _show = NO;

        
        CGFloat gapX = 50;
        CGFloat gapY =8;

        int alarmButtonCount = 7;
        CGFloat alarmButtonX = 10;
        CGFloat alarmButtonY =8;
        CGFloat buttonSize = 60;
        
        for (int i = 1; i < alarmButtonCount ;i++) {
            // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year

            UIButton *alarmButton = [[UIButton alloc]initWithFrame:CGRectMake(alarmButtonX, alarmButtonY, buttonSize, buttonSize)];
            [alarmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [alarmButton setTitleColor:[UIColor colorWithWhite:0.667 alpha:1.000] forState:UIControlStateNormal];
            alarmButton.titleLabel.font = [UIFont fontWithName:@"Avenir-light" size:14];
            alarmButton.layer.cornerRadius = buttonSize/2;
            alarmButton.layer.borderColor = [[UIColor colorWithWhite:0.667 alpha:1.000]CGColor];
            alarmButton.layer.borderWidth = 1.0f;
            alarmButton.tag = i;
            [self addSubview:alarmButton];
            alarmButtonX += buttonSize + gapX;
            
            if (i%3==0 && i != 6) {
                alarmButtonY += buttonSize + gapY;
                alarmButtonX -= 3*(buttonSize+gapX);
            }
            
            switch (i) {
                case 1:
                    [alarmButton setTitle:@"Never" forState:UIControlStateNormal];
                    break;
                case 2:
                    [alarmButton setTitle:@"Day" forState:UIControlStateNormal];
                    break;
                case 3:
                    [alarmButton setTitle:@"Week" forState:UIControlStateNormal];
                    break;
                case 4:
                    [alarmButton setTitle:@"2 Week" forState:UIControlStateNormal];
                    break;
                case 5:
                    [alarmButton setTitle:@"Month" forState:UIControlStateNormal];
                    break;
                case 6:
                    [alarmButton setTitle:@"Year" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }

        }        
    }
    return self;
}

@end
