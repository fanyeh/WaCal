//
//  DiaryEntryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryEntryViewController.h"

@interface DiaryEntryViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *diaryEntryView;
@end

@implementation DiaryEntryViewController

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
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(saveDiary)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    _diaryEntryView.delegate = self;
    [_diaryEntryView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveDiary
{
    [_delegate diaryDetails:_diaryEntryView.text];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
