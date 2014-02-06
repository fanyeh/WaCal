//
//  ProfileDataStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/11.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ProfileData;

@interface ProfileDataStore : NSObject
{
    NSMutableArray *allItems;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

+ (ProfileDataStore *)sharedStore;

- (void)removeItem:(ProfileData *)p;

- (NSArray *)allItems;

- (ProfileData *)createItem;

- (void)moveItemAtIndex:(int)from
                toIndex:(int)to;

- (BOOL)saveChanges;

- (void)loadAllItems;

@end
