//
//  DiaryPhotoCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryPhotoCell.h"

@implementation DiaryPhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _photoView = [[UIImageView alloc]init];
        [self addSubview:_photoView];
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
