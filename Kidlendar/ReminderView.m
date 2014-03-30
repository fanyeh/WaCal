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
    self = [super initWithFrame:CGRectMake(0,0, 320, 216)];
    if (self) {
        // Initialization code
        _show = NO;
        CGFloat gapX = 35;
        CGFloat gapY = 9;
        int alarmButtonCount = 10;
        CGFloat alarmButtonX = 35;
        CGFloat alarmButtonY = 9;
        CGFloat buttonSize = 60;
        
        // Tag : 1 - on time , 2 - 5min , 3 - 15min , 4 - 30min , 5 - 1hour , 6 - 2hour ,7 - 1day , 8 - 2Day , 9 - 1week

        for (int i = 1; i < alarmButtonCount ;i++) {
            
            ReminderButton *alarmButton = [[ReminderButton alloc]initWithFrame:CGRectMake(alarmButtonX, alarmButtonY, buttonSize, buttonSize)];
            
            alarmButton.tag = i;
            [self addSubview:alarmButton];
            alarmButtonX += buttonSize + gapX;

            if (i%3==0 && i != 9) {
                alarmButtonY += buttonSize + gapY;
                alarmButtonX -= 3*(buttonSize+gapX);
            }
            
            switch (i) {
                case 1:
                    [alarmButton setTitle:@"On\nTime" forState:UIControlStateNormal];
                    break;
                case 2:
                    [alarmButton setTitle:@"5\nMin" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 300;
                    break;
                case 3:
                    [alarmButton setTitle:@"15\nMin" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 900;
                    break;
                case 4:
                    [alarmButton setTitle:@"30\nMin" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 1800;
                    break;
                case 5:
                    [alarmButton setTitle:@"1\nHour" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 3600;
                    break;
                case 6:
                    [alarmButton setTitle:@"2\nHours" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 7200;
                    break;
                case 7:
                    [alarmButton setTitle:@"1\nDay" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 86400;
                    break;
                case 8:
                    [alarmButton setTitle:@"2\nDays" forState:UIControlStateNormal];
                    alarmButton.timeOffset = 172800;
                    break;
                case 9:
                    [alarmButton setTitle:@"1\nWeek" forState:UIControlStateNormal];
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
