//
//  MediaTableViewController.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface MediaTableViewController : UITableViewController
@property NSMutableDictionary *assets;
@property ALAssetsLibrary *library;
@property NSMutableArray *assetGroups;
@end
