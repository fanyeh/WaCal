//
//  DiaryTableViewCell.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryTableViewCell.h"

@implementation DiaryTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
//        _cellView.layer.cornerRadius = 5.0f;
//        _cellView.layer.shadowColor = [[UIColor redColor]CGColor];
//        _cellView.layer.shadowOpacity = 0.5f;
//        _cellView.layer.shadowOffset = CGSizeMake(5 , 5);
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
