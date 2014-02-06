//
//  DiaryContentView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryCell.h"
#import "UIImage+Resize.h"

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
    }
    return self;
}

- (void)setupImages:(NSMutableArray *)diaryPhotos
{
    CGFloat xoff = 0;
    CGFloat yoff = 0;
    // create rotations at load so that they are consistent during prepareLayout
    for (NSInteger i = 0; i < [diaryPhotos count]; i++) {
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(xoff, yoff, 80, 80)];
        imageView.layer.borderColor = [[UIColor whiteColor]CGColor];
        imageView.layer.borderWidth = 1.0f;
        [imageView setContentMode:UIViewContentModeScaleToFill];
        imageView.image = diaryPhotos[i];
        [self addSubview:imageView];
        xoff +=3;
        yoff +=3;
    }
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
