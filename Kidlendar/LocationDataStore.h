//
//  LocationDataStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationData.h"

@interface LocationDataStore : NSObject
{
    NSMutableDictionary *allItems;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
}

+ (LocationDataStore *)sharedStore;

- (void)removeItem:(LocationData *)location;

- (NSMutableDictionary *)allItems;

- (LocationData *)createItemWithKey:(NSString *)key;

//- (void)moveItemAtIndex:(int)from
//                toIndex:(int)to;

- (BOOL)saveChanges;

- (void)loadAllItems;
@end
