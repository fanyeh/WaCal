//
//  SwitchCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "SwitchCell.h"

@implementation SwitchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _cellSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(0, 0, 51, 31)];
        _cellSwitch.on = YES;
        _cellSwitch.center = self.center;
        _cellSwitch.frame = CGRectOffset(_cellSwitch.frame, self.frame.size.width/2 - _cellSwitch.frame.size.width/2 - 10 , 0);
        [self.contentView addSubview:_cellSwitch];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
