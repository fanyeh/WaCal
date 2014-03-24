//
//  UploadStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadStore : NSObject
{
    NSMutableDictionary *allTasks;
}
+ (UploadStore *)sharedStore;

- (NSMutableDictionary *)allTasks;

@end
