//
//  VideoView.h
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/8.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoView : UIView
@property (strong,nonatomic) UIImageView *videoImageView;
@property (strong,nonatomic) UILabel *videoDeleteLabel;

- (id)initWithFrame:(CGRect)frame deleteLabelSize:(NSInteger)size;

@end
