//
//  PhotoCollectionHeaderView.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/13.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "PhotoCollectionHeaderView.h"

@implementation PhotoCollectionHeaderView
{
    UINavigationBar *navBar;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        navBar = [[UINavigationBar alloc]initWithFrame:frame];
        [self addSubview:navBar];
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
