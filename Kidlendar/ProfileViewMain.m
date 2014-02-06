//
//  ProfileViewMain.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "ProfileViewMain.h"
#import "ProfileData.h"

@implementation ProfileViewMain

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andProfile:(ProfileData *)profile
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _picture = [[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 100, 100)];
        _picture.backgroundColor = [UIColor grayColor];
        
        //_picture.image = profile.photo;
        [self addSubview:_picture];
        
        float xoffset = 120;
        float yoffset = 10;
        float labelWdith = 50;
        float labelHeight = 20;
        float gap = 5;
        
        _name = [[customLabel alloc]initWithFrame:CGRectMake(xoffset, yoffset, labelWdith, labelHeight)];
        _name.text = @"name";
        [self addSubview:_name];
        yoffset = yoffset + labelHeight + gap;
        
        _birthday = [[customLabel alloc]initWithFrame:CGRectMake(xoffset, yoffset, labelWdith, labelHeight)];
        _birthday.text = @"birthday";
        [self addSubview:_birthday];
        yoffset = yoffset + labelHeight + gap;

        _weight = [[customLabel alloc]initWithFrame:CGRectMake(xoffset, yoffset, labelWdith, labelHeight)];
        _weight.text = @"Weight";
        [self addSubview:_weight];
        yoffset = yoffset + labelHeight + gap;

        _height = [[customLabel alloc]initWithFrame:CGRectMake(xoffset, yoffset, labelWdith, labelHeight)];
        _height.text = @"Height";
        [self addSubview:_height];
        yoffset = yoffset + labelHeight + gap;

        _gender = [[customLabel alloc]initWithFrame:CGRectMake(xoffset, yoffset, labelWdith, labelHeight)];
        _gender.text = @"Gender";
        [self addSubview:_gender];

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
