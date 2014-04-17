//
//  DiaryTableViewCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/21.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleProgressView.h"

@interface DiaryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *diarySubject;
@property (weak, nonatomic) IBOutlet UIImageView *videoPlayButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *videoPlayView;
@property (weak, nonatomic) IBOutlet UIImageView *locationTag;
@property (weak, nonatomic) IBOutlet UIImageView *uploadCircle;
@property (weak, nonatomic) IBOutlet UILabel *diaryDetail;

@end
