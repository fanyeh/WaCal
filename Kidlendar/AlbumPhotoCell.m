//
//  AlbumPhotoCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "AlbumPhotoCell.h"
#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]


@implementation AlbumPhotoCell
{
    UIView *highlightMask;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat labelSize =20;
        _selectNumber = [[UILabel alloc]initWithFrame:CGRectMake(self.contentView.bounds.size.width - labelSize,
                                                                0,
                                                                labelSize,
                                                                labelSize)
                         ];
        _selectNumber.backgroundColor = Rgb2UIColor(33, 138, 251);
        _selectNumber.adjustsFontSizeToFitWidth = YES;
        _selectNumber.textAlignment = NSTextAlignmentCenter;
        _selectNumber.textColor = [UIColor whiteColor];
        
        highlightMask = [[UIView alloc]initWithFrame:self.contentView.frame];
        highlightMask.layer.borderWidth = 2.0f;
        highlightMask.layer.borderColor = [_selectNumber.backgroundColor CGColor];
        [highlightMask addSubview:_selectNumber];
        [self addSubview:highlightMask];
        highlightMask.hidden = YES;

    }
    return self;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        highlightMask.hidden = NO;
        NSLog(@"Select");
    }
    else {
        highlightMask.hidden = YES;

        NSLog(@"Deselect");
    }
}

@end
