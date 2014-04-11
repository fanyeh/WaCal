//
//  LayoutCell.h
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/8.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LayoutCell : UICollectionViewCell
@property (nonatomic) BOOL isPhotoCountSection;

- (void)drawLayoutWithViewSize:(CGSize)size andFrames:(NSArray *)frames andDirection:(UICollectionViewScrollDirection)direction;

@end
