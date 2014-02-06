//
//  CalendarStore.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/23.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "CalendarStore.h"

@implementation CalendarStore
+ (CalendarStore *)sharedStore
{
    static CalendarStore *sharedStore = nil;
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
        self.eventStore = [[EKEventStore alloc]init];
    }
    return self;
}

@end
