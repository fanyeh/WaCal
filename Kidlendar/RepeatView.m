//
//  Repeat.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "RepeatView.h"
#import "ReminderButton.h"

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
    self = [super initWithFrame:CGRectMake(0,0, 320, 216)];
    self = [super init];
    if (self) {
        // Initialization code
        
        _show = NO;
        int alarmButtonCount = 7;
        CGFloat alarmButtonX = 35;
        CGFloat alarmButtonY = 32;
        CGFloat buttonSize = 60;
        CGFloat gapX = 35;
        CGFloat gapY =8;
        
        for (int i = 1; i < alarmButtonCount ;i++) {
            // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year

            ReminderButton *alarmButton = [[ReminderButton alloc]initWithFrame:CGRectMake(alarmButtonX, alarmButtonY, buttonSize, buttonSize)];
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
                    [alarmButton setTitle:@"Bi-Week" forState:UIControlStateNormal];
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
