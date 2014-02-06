//
//  AlarmViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "AlarmViewController.h"
#import "CalendarStore.h"

@interface AlarmViewController ()
{
    UIImageView *backgroundImageView;
    EKAlarm *alarm;
}
@end

@implementation AlarmViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    backgroundImageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    backgroundImageView.image = _backgroundImage;
    [self makeRoundButton];
    [self checkAlarm];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)makeRoundButton
{
    for (UIView *l in self.view.subviews) {
        if (l.tag > 0) {
            l.layer.cornerRadius = l.frame.size.width/2;
            l.layer.borderColor = [[UIColor colorWithWhite:0.298 alpha:1.000]CGColor];
            l.layer.borderWidth = 2.0f;
        }
    }
}

- (void)removeAllAlarms
{
    if (_event.hasAlarms) {
        for (EKAlarm *a in _event.alarms) {
            [_event removeAlarm:a];
        }
    }
}

- (void)checkAlarm
{
    int tag;
    if (_event.hasAlarms) {
        for (EKAlarm *a in _event.alarms) {
            NSLog(@"alarm %@",a);
            if (a.absoluteDate)
                tag = 1;
            else {
                int offsetMin =  (int)(a.relativeOffset*-1/60);
                switch (offsetMin) {
                    case 5:
                        tag = 2;
                        break;
                    case 15:
                        tag = 3;
                        break;
                    case 30:
                        tag = 4;
                        break;
                    case 60:
                        tag = 5;
                        break;
                    case 120:
                        tag = 6;
                        break;
                    case 1440:
                        tag = 7;
                        break;
                    case 2880:
                        tag = 8;
                        break;
                    case 10080:
                        tag = 9;
                        break;
                    default:
                        break;
                }
            }
        }
        
        if (tag > 0) {
            for (UIButton *b in self.view.subviews) {
                if (b.tag == tag) {
                    [self createAlarm:tag];
                    [b setSelected:YES];
                    b.layer.borderColor = [[UIColor greenColor]CGColor];
                    break;
                }
            }
        }
    }
}

- (IBAction)alarmTime:(UIButton *)sender
{
    // Tag : 1 - on time , 2 - 5min , 3 - 15min , 4 - 30min , 5 - 1hour , 6 - 2hour ,7 - 1day , 8 - 2Day , 9 - 1week
    [self createAlarm:sender.tag];
    if([sender isSelected]){
        [sender setSelected:NO];
        sender.layer.borderColor = [[UIColor colorWithWhite:0.298 alpha:1.000]CGColor];
        
    } else {
        [sender setSelected:YES];
        sender.layer.borderColor = [[UIColor greenColor]CGColor];
        // Change all other buttons to unselect
        for (UIButton *b in self.view.subviews) {
            if (b.tag > 0 && b.tag != sender.tag) {
                b.layer.borderColor = [[UIColor colorWithWhite:0.298 alpha:1.000]CGColor];
                [b setSelected:NO];
            }
        }
    }
}
- (IBAction)doneBtn:(id)sender
{
    // Create new event
    [self removeAllAlarms];
    [_event addAlarm:alarm];
    [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)cancelBtn:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)createAlarm:(NSInteger)i
{
    switch (i) {
        case 1:
            alarm = [EKAlarm alarmWithAbsoluteDate:_event.startDate];
            break;
        case 2:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*5];
            break;
        case 3:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*15];
            break;
        case 4:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*30];
            break;
        case 5:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60];
            break;
        case 6:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*120];
            break;
        case 7:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24];
            break;
        case 8:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24*2];
            break;
        case 9:
            alarm = [EKAlarm alarmWithRelativeOffset:-60*60*24*7];
            break;
        default:
            break;
    }
}



@end
