//
//  profileCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/31.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ProfileData;
@class DiaryData;

@interface profileCell : UITableViewCell
@property (strong , nonatomic) UIImageView *profileImageView;
@property (strong,nonatomic) ProfileData *profileData;
@property (strong,nonatomic) DiaryData *diaryData;

@end
