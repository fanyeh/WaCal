//
//  FilterCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "FilterCell.h"

@implementation FilterCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        CGFloat cellWidth = self.contentView.frame.size.width;
        CGFloat cellHeight = self.contentView.frame.size.height;
        
        _cellImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,0,cellWidth,cellWidth)];
        _filterNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                    cellWidth + 10,
                                                                    cellWidth,
                                                                    cellHeight - cellWidth - 10)];
        _filterNameLabel.textColor = [UIColor whiteColor];
        _filterNameLabel.font = [UIFont fontWithName:@"Helvetica-bold" size:13];
        _filterNameLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.contentView addSubview:_cellImageView];
        [self.contentView addSubview:_filterNameLabel];
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
