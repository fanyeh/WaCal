//
//  DiaryBrowseViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiaryPhotoCollectionViewController.h"
#import "UIImage+Resize.h"

@class DiaryData;

@protocol PhotosDelegate <NSObject>
@optional
-(NSMutableArray *)selectedPhotos;
@end

@interface DiaryCreateViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UITextViewDelegate,UIScrollViewDelegate>
{
    __weak id<PhotosDelegate>_delegate;
}
@property (nonatomic,weak)id<PhotosDelegate>delegate;
@property (strong, nonatomic)  UICollectionView *collectionView;
@property (strong,nonatomic) NSMutableArray *selectedPhotos;
@property (strong,nonatomic) DiaryData *diary;

@end
