//
//  RecurrenceViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "RecurrenceViewController.h"
#import "CalendarStore.h"

@interface RecurrenceViewController ()
{
    UIImageView *backgroundImageView;
    EKRecurrenceRule *recurrenceRule;
}
@end

@implementation RecurrenceViewController

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
    [self checkRule];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)makeRoundButton
{
    for (UIButton *l in self.view.subviews) {
        if (l.tag > 0) {
            l.layer.cornerRadius = l.frame.size.width/2;
            l.layer.borderColor = [[UIColor colorWithWhite:0.298 alpha:1.000]CGColor];
            l.layer.borderWidth = 2.0f;
        }
    }
}

- (IBAction)recurrenceBtn:(UIButton *)sender
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
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

- (void)removeAllRules
{
    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in _event.recurrenceRules) {
            [_event removeRecurrenceRule:r];
        }
    }
}

- (void)checkRule
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    int tag;
    if (_event.hasRecurrenceRules) {
        for (EKRecurrenceRule *r in _event.recurrenceRules) {
            EKRecurrenceFrequency frequency = r.frequency;
            NSInteger interval = r.interval;
            switch (frequency) {
                case EKRecurrenceFrequencyDaily:
                    tag = 2;
                    break;
                case EKRecurrenceFrequencyWeekly:
                    if (interval == 1)
                        tag = 3;
                    else
                        tag = 4;
                    break;
                case EKRecurrenceFrequencyMonthly:
                    tag = 5;
                    break;
                case EKRecurrenceFrequencyYearly:
                    tag = 6;
                    break;
                default:
                    break;
            }
        }
    }
    else
        tag = 1;
    
    if (tag > 0) {
        for (UIButton *b in self.view.subviews) {
            if (b.tag == tag) {
                [self createRule:tag];
                [b setSelected:YES];
                b.layer.borderColor = [[UIColor greenColor]CGColor];
                break;
            }
        }
    }
}

- (void)createRule:(NSInteger )tag
{
    // Tag 1 - Never ; 2 - Day ; 3 - Week ; 4 - Two Week ; 5 - Month ; 6 - Year
    switch (tag) {
        case 1:
            // Does nothing
            break;
        case 2:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil];
            break;
        case 3:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil];
            break;
        case 4:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:2 end:nil];
            break;
        case 5:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly interval:1 end:nil];
            break;
        case 6:
            recurrenceRule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyYearly interval:1 end:nil];
            break;
        default:
            break;
    }
}
- (IBAction)cancelBtn:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)doneBtn:(id)sender
{
    // Create new recurrence rule
    [self removeAllRules];
    [_event addRecurrenceRule:recurrenceRule];
    [[[CalendarStore sharedStore]eventStore] saveEvent:_event span:EKSpanThisEvent commit:YES error:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
