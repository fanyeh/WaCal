//
//  AlbumPhotoCell.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ALAsset;

@interface AlbumPhotoCell : UICollectionViewCell
@property (strong,nonatomic) UILabel *selectNumber;
@property (strong,nonatomic) UIImageView *videoLabel;

@property (strong,nonatomic) UILabel *videoTimeLabel;
@property (strong,nonatomic) UIImageView *cellImageView;
@property (strong,nonatomic) ALAsset *asset;
- (void) formatVideoInterval: (NSNumber *) interval;
@end
