//
//  ReminderView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "ReminderView.h"
#import "ReminderButton.h"

@implementation ReminderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init {
    self = [super initWithFrame:CGRectMake(10,568, 300, 216)];
    if (self) {
        // Initialization code
        _show = NO;
//        self.backgroundColor = [UIColor blackColor];
        
        CGFloat gapX = 50;
        CGFloat gapY = 8;
        int alarmButtonCount = 10;
        CGFloat alarmButtonX = 10;
        CGFloat alarmButtonY = 8;
        CGFloat buttonSize = 60;
        
        // Tag : 1 - on time , 2 - 5min , 3 - 15min , 4 - 30min , 5 - 1hour , 6 - 2hour ,7 - 1day , 8 - 2Day , 9 - 1week

        for (int i = 1; i < alarmButtonCount ;i++) {
            
            ReminderButton *alarmButton = [[ReminderButton alloc]initWithFrame:CGRectMake(alarmButtonX, alarmButtonY, buttonSize, buttonSize)];
            
            [alarmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [alarmButton setTitleColor:[UIColor colorWithWhite:0.667 alpha:1.000] forState:UIControlStateNormal];
            alarmButton.titleLabel.font = [UIFont fontWithName:@"Avenir-light" size:14];
            alarmButton.layer.borderColor = [[UIColor colorWithWhite:0.667 alpha:1.000]CGColor];
            alarmButton.layer.borderWidth = 1.0f;
            alarmButton.layer.cornerRadius = buttonSize/2;
            alarmButton.tag = i;
            [self addSubview:alarmButton];
            alarmButtonX += buttonSize + gapX;

            if (i%3==0 && i != 9) {
                alarmButtonY += buttonSize + gapY;
                alarmButtonX -= 3*(buttonSize+gapX);
            }
            
            switch (i) {
                case 1:
                    [alarmButton setTitle:@"OnTime" forState:UIControlStateNormal];
                    break;
                case 2:
                    [alarmButton setTitle:@"5 Min" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 300;
                    break;
                case 3:
                    [alarmButton setTitle:@"15 Min" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 900;
                    break;
                case 4:
                    [alarmButton setTitle:@"30 Min" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 1800;
                    break;
                case 5:
                    [alarmButton setTitle:@"1 Hour" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 3600;
                    break;
                case 6:
                    [alarmButton setTitle:@"2 Hours" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 7200;
                    break;
                case 7:
                    [alarmButton setTitle:@"1 Day" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 86400;
                    break;
                case 8:
                    [alarmButton setTitle:@"2 Days" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 172800;
                    break;
                case 9:
                    [alarmButton setTitle:@"1 Week" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 604800;
                    break;
                    
                default:
                    break;
            }
        }
    }
    return self;
}

@end
