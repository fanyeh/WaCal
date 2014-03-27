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
        _photoView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:_photoView];
        
        _deleteBadger = [[UILabel alloc]init];
        _deleteBadger.text = @"X";
        _deleteBadger.textColor = [UIColor whiteColor];
        _deleteBadger.textAlignment = NSTextAlignmentCenter;
        _deleteBadger.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        _deleteBadger.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        _deleteBadger.userInteractionEnabled = YES;
        [self addSubview:_deleteBadger];
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
