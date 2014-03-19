//
//  DiaryDataStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/30.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiaryData;

@interface DiaryDataStore : NSObject
{
    NSMutableArray *allItems;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

+ (DiaryDataStore *)sharedStore;

- (void)removeItem:(DiaryData *)p;

- (NSMutableArray *)allItems;

- (DiaryData *)createItem;

- (void)moveItemAtIndex:(int)from
                toIndex:(int)to;

- (BOOL)saveChanges;

- (void)loadAllItems;

@end
