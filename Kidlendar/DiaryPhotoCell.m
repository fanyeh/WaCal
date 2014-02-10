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
        _deleteBadger.textAlignment = NSTextAlignmentCenter;
        _deleteBadger.backgroundColor = [UIColor redColor];
        _deleteBadger.hidden = YES;
        [self.contentView addSubview:_deleteBadger];
    }
    return self;
}

- (void)deletePhotoBadger:(BOOL)deletePhotoBadger
{
    if (deletePhotoBadger) {
        _deleteBadger.frame = CGRectMake(self.frame.size.width-25, 0, 25, 25);
        self.deleteBadger.hidden = NO;
        
    }
    else
        self.deleteBadger.hidden = YES;
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
