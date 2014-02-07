//
//  DiaryBrowseViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/27.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DiaryPhotoCollectionViewController.h"
#import "PassFilteredImage.h"
#import "UIImage+Resize.h"

@class DiaryData;

@interface DiaryCreateViewController : UIViewController <UICollectionViewDataSource,UICollectionViewDelegate,PassFilteredImage,UICollectionViewDelegateFlowLayout,UITextFieldDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong,nonatomic) NSMutableArray *selectedPhotos;
@property (strong,nonatomic) DiaryData *diary;

@end
