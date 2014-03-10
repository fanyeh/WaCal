//
//  PhotoLoader.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/12.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "PhotoLoader.h"

@implementation PhotoLoader

- (id)initWithSourceType:(SourceType)sourceType
{
    self = [super init];
    if (self) {
        [self preparePhotos:sourceType];
    }
    return self;
}

- (void)preparePhotos:(SourceType)sourceType
{
    _assetGroups = [[NSMutableArray alloc]init];
    _library = [[ALAssetsLibrary alloc]init];
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

@end
