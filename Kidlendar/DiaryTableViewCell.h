//
//  DiaryTableViewCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiaryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *cellView;
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekdayLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetail;
@property (weak, nonatomic) IBOutlet UILabel *diarySubject;

@end
