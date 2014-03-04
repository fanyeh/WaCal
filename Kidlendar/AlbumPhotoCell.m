//
//  AlbumPhotoCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "AlbumPhotoCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
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
        _cellImageView = [[UIImageView alloc]initWithFrame:self.contentView.frame];
        [self.contentView addSubview:_cellImageView];
        
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
        highlightMask.layer.borderWidth = 3.0f;
        highlightMask.layer.borderColor = [_selectNumber.backgroundColor CGColor];
        [highlightMask addSubview:_selectNumber];
        [self addSubview:highlightMask];
        highlightMask.hidden = YES;
        
        _videoTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                   self.contentView.frame.origin.y+self.contentView.frame.size.height-20,
                                                                   self.contentView.frame.size.width,
                                                                   20)];
        _videoTimeLabel.textColor = [UIColor whiteColor];
        _videoTimeLabel.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        _videoTimeLabel.font = [UIFont fontWithName:@"Avenir-light" size:15];
        _videoTimeLabel.textAlignment = NSTextAlignmentRight;
        _videoTimeLabel.hidden = YES;
        [self.contentView addSubview:_videoTimeLabel];
    }
    return self;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if ([_asset valueForProperty:ALAssetPropertyType]==ALAssetTypeVideo) {
        _selectNumber.hidden = YES;
    } else
        _selectNumber.hidden = NO;
    
    if (selected) {
        highlightMask.hidden = NO;
    }
    else {
        highlightMask.hidden = YES;
    }
}

- (void) formatVideoInterval: (NSNumber *) interval
{
    unsigned long seconds = [interval integerValue];
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    
    NSMutableString * result = [NSMutableString new];
    
    if(hours)
        [result appendFormat: @"%ld:", hours];
    
    [result appendFormat: @"%2ld:", minutes];
    if (seconds < 10)
        [result appendFormat: @"0%ld", seconds];
    else
        [result appendFormat: @"%2ld", seconds];
    
    _videoTimeLabel.text = result;
    _videoTimeLabel.hidden = NO;
}


@end
