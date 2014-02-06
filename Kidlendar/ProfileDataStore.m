//
//  ProfileDataStore.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/11.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "ProfileDataStore.h"
#import "ProfileData.h"
#import "ProfileImageStore.h"
#import "KidlendarAppDelegate.h"

@implementation ProfileDataStore

+ (ProfileDataStore *)sharedStore
{
    static ProfileDataStore *sharedStore = nil;
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
        
        // Read in Kidlendar.xcdatamodeld
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
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"ProfileData"];
        [request setEntity:e];
        
        NSSortDescriptor *sd = [NSSortDescriptor 
                                sortDescriptorWithKey:@"orderingValue"
                                ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObject:sd]];
        
        NSError *error;
        NSArray *result = [context executeFetchRequest:request error:&error];
        if (!result) {
            [NSException raise:@"Fetch failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        allItems = [[NSMutableArray alloc] initWithArray:result];
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

- (void)removeItem:(ProfileData *)p
{
    NSString *key = [p imageKey];
    [[ProfileImageStore sharedStore] deleteImageForKey:key];
    [context deleteObject:p];
    [allItems removeObjectIdenticalTo:p];
}

- (NSArray *)allItems
{
    return allItems;
}

- (void)moveItemAtIndex:(int)from
                toIndex:(int)to
{
    if (from == to) {
        return;
    }
    // Get pointer to object being moved so we can re-insert it
    ProfileData *p = [allItems objectAtIndex:from];

    // Remove p from array
    [allItems removeObjectAtIndex:from];

    // Insert p in array at new location
    [allItems insertObject:p atIndex:to];

// Computing a new orderValue for the object that was moved
    double lowerBound = 0.0;

    // Is there an object before it in the array?
    if (to > 0) {
        lowerBound = [[allItems objectAtIndex:to - 1] orderingValue];
    } else {
        lowerBound = [[allItems objectAtIndex:1] orderingValue] - 2.0;
    }

    double upperBound = 0.0;

    // Is there an object after it in the array?
    if (to < [allItems count] - 1) {
        upperBound = [[allItems objectAtIndex:to + 1] orderingValue];
    } else {
        upperBound = [[allItems objectAtIndex:to - 1] orderingValue] + 2.0;
    }
    
    double newOrderValue = (lowerBound + upperBound) / 2.0;

    NSLog(@"moving to order %f", newOrderValue);
    [p setOrderingValue:newOrderValue];
}

- (ProfileData *)createItem
{
    double order;
    if ([allItems count] == 0) {
        order = 1.0;
    } else {
        order = [[allItems lastObject] orderingValue] + 1.0;
    }
    ProfileData *p = [NSEntityDescription insertNewObjectForEntityForName:@"ProfileData"
                                                inManagedObjectContext:context];
    [p setOrderingValue:order];
    [allItems addObject:p];
    return p;
}

@end
