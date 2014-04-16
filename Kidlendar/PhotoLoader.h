//
//  PhotoLoader.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/12.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger, SourceType)
{
    kSourceTypePhoto,
    kSourceTypeVideo,
    kSourceTypeAll
};

@interface PhotoLoader : NSObject
@property ALAssetsLibrary *library;
@property NSMutableArray *assetGroups;
@property (nonatomic,strong) NSMutableDictionary *sourceDictionary;
- (id)initWithSourceType:(SourceType)sourceType;
+ (ALAssetsLibrary *)defaultAssetsLibrary;
- (void)createPhotoAlbum;
- (void)saveImage:(UIImage *)image;


@end
