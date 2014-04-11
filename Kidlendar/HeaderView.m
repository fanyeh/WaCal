//
//  HeaderView.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/10.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "HeaderView.h"

@implementation HeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 320, 20)];
        _headerLabel.backgroundColor = [UIColor clearColor];
        _headerLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
        [self addSubview:_headerLabel];
    }
    return self;
}

@end
