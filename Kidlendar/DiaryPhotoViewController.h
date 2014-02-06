//
//  DiaryPhotoController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PassFilteredImage.h"

@interface DiaryPhotoViewController : UIViewController
@property (strong,nonatomic) UIImage *photoImage;
@property id <PassFilteredImage> PassFilteredImageDelegate;
@property NSInteger index;
@end
