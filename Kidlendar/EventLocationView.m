//
//  EventLocationView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/15.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "EventLocationView.h"

@implementation EventLocationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.8];
        _locationField = [[UITextField alloc]initWithFrame:CGRectMake(10, 77, 300, 50)];
        _locationField.backgroundColor =  [UIColor colorWithWhite:0.8 alpha:0.8];
        _locationField.placeholder = @"Please enter location";
        _locationField.font = [UIFont fontWithName:@"Avenir-Light" size:25];
        _locationField.tag = 3;
        _locationField.rightViewMode = UITextFieldViewModeAlways;
        _locationField.rightView = [[UIView alloc]initWithFrame:CGRectMake(250, 77, 50, 50)];
        _locationField.rightView.backgroundColor = [UIColor redColor];
        [self addSubview:_locationField];
        
        _searchedLocation = [[UITableView alloc]initWithFrame:CGRectMake(10, 128, 300, 210)];
        [self addSubview:_searchedLocation];
    }
    return self;
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
