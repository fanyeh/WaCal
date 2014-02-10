//
//  DiaryPhotoCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiaryPhotoCell : UICollectionViewCell
@property (strong,nonatomic) UIImageView *photoView;
@property (strong,nonatomic) UILabel *deleteBadger;
- (void)deletePhotoBadger:(BOOL)deletePhotoBadger;

@end
