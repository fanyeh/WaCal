//
//  DiaryDataStore.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/30.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryDataStore.h"
#import "DiaryData.h"
#import "KidlendarAppDelegate.h"
#import "CloudData.h"

@implementation DiaryDataStore
+ (DiaryDataStore *)sharedStore
{
    static DiaryDataStore *sharedStore = nil;
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
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"DiaryData"];
        [request setEntity:e];
        
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
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

- (void)removeItem:(DiaryData *)d
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:d.diaryKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] removeItemAtPath:dataPath error:nil]; //Delete folder
    NSLog(@"Delete DatePath %@",dataPath);
    [allItems removeObjectIdenticalTo:d];
    [context deleteObject:d.cloudRelationship];
    [context deleteObject:d];
    [self saveChanges];
}

- (NSMutableArray *)allItems
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
    DiaryData *d = [allItems objectAtIndex:from];
    
    // Remove p from array
    [allItems removeObjectAtIndex:from];
    
    // Insert p in array at new location
    [allItems insertObject:d atIndex:to];
    
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
    [d setOrderingValue:newOrderValue];
}

- (DiaryData *)createItem
{
    double order;
    if ([allItems count] == 0) {
        order = 1.0;
    } else {
        order = [[allItems lastObject] orderingValue] + 1.0;
    }
    
    DiaryData *d = [NSEntityDescription insertNewObjectForEntityForName:@"DiaryData"
                                                   inManagedObjectContext:context];
    
    d.cloudRelationship = [NSEntityDescription insertNewObjectForEntityForName:@"CloudData"
                                                 inManagedObjectContext:context];

    [d setOrderingValue:order];
    
    // Create a CFUUID object - it knows how to create unique identifier strings
    CFUUIDRef newUniqueID = CFUUIDCreate (kCFAllocatorDefault);
    
    // Create a string from unique identifier
    CFStringRef newUniqueIDString =
    CFUUIDCreateString (kCFAllocatorDefault, newUniqueID);
    
    // Use that unique ID to set our profile
    NSString *key = (__bridge NSString *)newUniqueIDString;
    
    [d setDiaryKey:key];
    
    [allItems addObject:d];
    
    // Create sub directory name using key for diary under document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:key];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil]; //Create folder
    
    CFRelease(newUniqueID);
    CFRelease(newUniqueIDString);
    return d;
}
@end
