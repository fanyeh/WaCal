//
//  DiaryContentView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryCell.h"

@implementation DiaryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _subjectLabel = [[UILabel alloc]initWithFrame:CGRectMake(12,95,80,10)];
        //_subjectLabel.backgroundColor = [UIColor blackColor];
        [_subjectLabel adjustsFontSizeToFitWidth];
        [self addSubview:_subjectLabel];
        
        _diaryImageView = [[UIImageView alloc]initWithFrame:self.contentView.frame];
        [self addSubview:_diaryImageView];
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
