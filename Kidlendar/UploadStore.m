//
//  UploadStore.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/24.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "UploadStore.h"

@implementation UploadStore
+ (UploadStore *)sharedStore
{
    static UploadStore *sharedStore = nil;
    if(!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedStore];
}

- (id)init
{
    self = [super init];
    if(self) {
        allTasks = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSMutableDictionary *)allTasks
{
    return allTasks;
}

@end
