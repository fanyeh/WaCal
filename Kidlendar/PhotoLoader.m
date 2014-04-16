//
//  PhotoLoader.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/12.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "PhotoLoader.h"

@implementation PhotoLoader
{
    BOOL createAccount;
    ALAssetsGroup *wacalGroup;
}

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (id)initWithSourceType:(SourceType)sourceType
{
    self = [super init];
    if (self) {
        createAccount = YES;
        [self preparePhotos:sourceType];
    }
    return self;
}

- (void)preparePhotos:(SourceType)sourceType
{
    _assetGroups = [[NSMutableArray alloc]init];
    _library = [PhotoLoader defaultAssetsLibrary];
    _sourceDictionary = [[NSMutableDictionary alloc]init];
    __block NSMutableArray *assets;
    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^ {
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            // When the enumeration is done, enumerationBlock is invoked with group set to nil.
            if (group == nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loadLibraySourceDone" object:nil];
                return;
            }
            
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            // Get all photos from library
            assets = [[NSMutableArray alloc]init];
            if (sourceType==kSourceTypePhoto) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            }
            else if (sourceType==kSourceTypeVideo) {
                [group setAssetsFilter:[ALAssetsFilter allVideos]];
            } else if (sourceType==kSourceTypeAll) {
                [group setAssetsFilter:[ALAssetsFilter allAssets]];
            }

            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop){
                if (asset) {
                    [assets addObject:asset];
                }
            }];
            
            [_sourceDictionary setObject:assets forKey:sGroupPropertyName];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"A problem occured %@", [error description]);
        };
        
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                    usingBlock:assetGroupEnumerator
                                  failureBlock:assetGroupEnumberatorFailure];
    });
}

- (void)createPhotoAlbum
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^ {
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
        {
            // When the enumeration is done, enumerationBlock is invoked with group set to nil.
            if (group == nil) {
                if (createAccount) {
                    [self.library addAssetsGroupAlbumWithName:@"W&Cal"
                                                  resultBlock:^(ALAssetsGroup *group) {
                                                      NSLog(@"added album: W&Cal");
                                                      __strong typeof(self) strongSelf = weakSelf;
                                                      if (strongSelf)
                                                          strongSelf->wacalGroup = group;
                                                  }
                                                 failureBlock:^(NSError *error) {
                                                     NSLog(@"error adding album");
                                                 }];
                }
                
                return;
            }
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            if ([sGroupPropertyName isEqualToString:@"W&Cal"]) {
                wacalGroup = group;
                createAccount = NO;
            }
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"A problem occured %@", [error description]);
        };
        
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                    usingBlock:assetGroupEnumerator
                                  failureBlock:assetGroupEnumberatorFailure];
    });
}

- (void)saveImage:(UIImage *)image
{
    CGImageRef img = [image CGImage];
    [self.library writeImageToSavedPhotosAlbum:img orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error.code == 0) {
            NSLog(@"saved image completed:\nurl: %@", assetURL);
            
            // try to get the asset
            [self.library assetForURL:assetURL
                          resultBlock:^(ALAsset *asset) {
                              // assign the photo to the album
                              [wacalGroup addAsset:asset];
                              NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], @"W&Cal");
                          }
                         failureBlock:^(NSError* error) {
                             NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                         }];
        }
        else {
            NSLog(@"saved image failed %@", [error localizedDescription]);
        }

    }];
}

@end
