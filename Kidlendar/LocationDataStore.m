//
//  LocationDataStore.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "LocationDataStore.h"
#import "LocationData.h"
#import "KidlendarAppDelegate.h"

@implementation LocationDataStore

+ (LocationDataStore *)sharedStore
{
    static LocationDataStore *sharedStore = nil;
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
        
        KidlendarAppDelegate *aDelegate = (KidlendarAppDelegate *)[[UIApplication sharedApplication] delegate];
        model = [aDelegate managedObjectModel];
        [aDelegate persistentStoreCoordinator];
        context = aDelegate.managedObjectContext;
        
        // The managed object context can manage undo, but we don't need it
        [context setUndoManager:nil];
        
        [self loadAllItems];
    }
    return self;
}

- (void)loadAllItems
{
    if (!allItems) {
        allItems = [[NSMutableDictionary alloc]init];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"LocationData"];
        [request setEntity:e];
        
        NSSortDescriptor *sd = [NSSortDescriptor
                                sortDescriptorWithKey:@"locationKey"
                                ascending:YES];
        
        [request setSortDescriptors:[NSArray arrayWithObject:sd]];
        
        NSError *error;
        NSArray *result = [context executeFetchRequest:request error:&error];
        
        if (!result) {
            [NSException raise:@"Location data fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        NSMutableArray *fetechedItems = [[NSMutableArray alloc] initWithArray:result];

        for (LocationData *l in fetechedItems) {
            NSString *locationKey = l.locationKey;
            [allItems setObject:l forKey:locationKey];
        }
    }
}

- (BOOL)saveChanges
{
    NSError *err = nil;
    BOOL successful = [context save:&err];
    if (!successful) {
        NSLog(@"Error saving: %@", [err localizedDescription]);
    }
    return successful;
}

- (void)removeItem:(LocationData *)loc
{
    [allItems removeObjectForKey:loc.locationKey];
    [context deleteObject:loc];
    [self saveChanges];
}

- (NSMutableDictionary *)allItems
{
    return allItems;
}

- (LocationData *)createItemWithKey:(NSString *)key
{
    LocationData *loc = [NSEntityDescription insertNewObjectForEntityForName:@"LocationData"
                                                      inManagedObjectContext:context];
    [loc setLocationKey:key];
    
    [allItems setObject:loc forKey:key];

    return loc;
}
@end