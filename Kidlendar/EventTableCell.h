//
//  EventTableCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventTableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *alldayLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (weak, nonatomic) IBOutlet UILabel *eventEndLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *birthdayIcon;
@property (weak, nonatomic) IBOutlet UIImageView *facebookIcon;

@end
