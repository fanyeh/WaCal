//
//  FilterCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "FilterCell.h"
#define MainColor [UIColor colorWithRed:(52 / 255.0) green:(132 / 255.0) blue:(176 / 255.0) alpha:1.0]


@implementation FilterCell
{
    UIView *highlightMask;

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat cellWidth = self.contentView.frame.size.width;
        CGFloat cellHeight = self.contentView.frame.size.height;
        
        _cellImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0,cellWidth,cellWidth)];
        _filterNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                    cellWidth + 8,
                                                                    cellWidth,
                                                                    cellHeight - cellWidth - 10)];
        _filterNameLabel.textColor = [UIColor whiteColor];
        _filterNameLabel.font = [UIFont fontWithName:@"Helvetica-bold" size:12];
        _filterNameLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.contentView addSubview:_cellImageView];
        [self.contentView addSubview:_filterNameLabel];
        
        highlightMask = [[UIView alloc]initWithFrame:_cellImageView.frame];
        highlightMask.layer.borderWidth = 3.0f;
        highlightMask.layer.borderColor = [MainColor CGColor];
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

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        highlightMask.hidden = NO;
    }
    else {
        highlightMask.hidden = YES;
    }
}

@end
