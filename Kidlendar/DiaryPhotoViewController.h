//
//  DiaryPhotoController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol filterImageDelegate <NSObject>
@required
- (void)filteredImage:(UIImage *)image indexPath:(NSIndexPath *)path;
@end

@interface DiaryPhotoViewController : UIViewController
{
    __weak id<filterImageDelegate>_delegate;
}
@property (strong,nonatomic) UIImage *photoImage;
@property (weak,nonatomic) id<filterImageDelegate>delegate;
@property NSIndexPath *indexPath;
@property CGSize cropRectSize;
@end
