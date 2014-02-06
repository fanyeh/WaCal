//
//  profileCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/31.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "profileCell.h"

@implementation profileCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _profileImageView = [[UIImageView alloc]init];
        [self addSubview:_profileImageView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

@end
