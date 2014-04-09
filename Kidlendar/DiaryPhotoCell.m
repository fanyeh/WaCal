//
//  DiaryPhotoCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryPhotoCell.h"

@implementation DiaryPhotoCell
{
    UIView *highlightMask;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.layer.borderColor = [MainColor CGColor];

        _photoView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:_photoView];
        
        _deleteBadger = [[UILabel alloc]init];
        _deleteBadger.text = @"✕";
        _deleteBadger.textColor = [UIColor whiteColor];
        _deleteBadger.textAlignment = NSTextAlignmentCenter;
        _deleteBadger.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        _deleteBadger.backgroundColor = TodayColor;
        _deleteBadger.userInteractionEnabled = YES;
        _deleteBadger.layer.masksToBounds = YES;
        [self addSubview:_deleteBadger];
        
        highlightMask = [[UIView alloc]initWithFrame:self.contentView.bounds];
        highlightMask.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        highlightMask.hidden = YES;
        
        [self addSubview:highlightMask];
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

-(void)showHighlight:(BOOL)show
{
    if (show) {
        highlightMask.frame = self.contentView.frame;
        highlightMask.hidden = NO;
    }
    else 
        highlightMask.hidden = YES;
    _isHighlight = show;
}

@end
