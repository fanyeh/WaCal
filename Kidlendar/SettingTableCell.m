//
//  SettingTableCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/22.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "SettingTableCell.h"

@implementation SettingTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
//        _calendarColorView.hidden = NO;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
//        _calendarColorView.hidden = YES;
    }
}

@end
