//
//  KidlendarAppDelegate.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/6.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "KidlendarAppDelegate.h"
#import "MonthViewController.h"
#import "DiaryTableViewController.h"
#import "CalendarStore.h"
#import <CoreData/CoreData.h>
#import "SettingViewController.h"
#import "DiaryCreateViewController.h"

NSString *const AccountFacebookAccountAccessGranted =  @"FacebookAccountAccessGranted";

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@implementation KidlendarAppDelegate
{
    UITabBarController *tbc;
}
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    self.accountStore = [[ACAccountStore alloc] init];

    // Init Calendar store
    [CalendarStore sharedStore];
    
    if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]==EKAuthorizationStatusAuthorized) {
        [self createAllViewControllers];
    }
    else {
        [[[CalendarStore sharedStore]eventStore] requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self createAllViewControllers];
                });
            }
            else
                NSLog(@"need permission , error %@",error);
        }];
    }

//    self.window.backgroundColor = [UIColor whiteColor];


    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBarTintColor:Rgb2UIColor(64 , 98 , 124)];

    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]]; //is the buttons text color
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0],NSFontAttributeName,
                          [UIColor whiteColor],NSForegroundColorAttributeName,nil];
    [[UINavigationBar appearance]setTitleTextAttributes:size];
    [[UITabBar appearance] setTintColor:Rgb2UIColor(64 , 98 , 124)]; //is the buttons text color

    
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)getFacebookAccount
{
    // 1
    ACAccountType *facebookAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    __weak KidlendarAppDelegate *weakSelf = self;
    // 2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 3
        NSDictionary *facebookOptions = @{ACFacebookAppIdKey : @"1450548605159832",
                                          ACFacebookPermissionsKey : @[@"email", @"read_stream",@"user_relationships", @"user_website"],
                                          ACFacebookAudienceKey : ACFacebookAudienceEveryone };
        // 4
        [weakSelf.accountStore requestAccessToAccountsWithType:facebookAccountType
                                                       options:facebookOptions
                                                    completion:^(BOOL granted, NSError *error) {
                                                        
                                                         // 5
                                                         if (granted)
                                                         {
                                                             [weakSelf getPublishStream];
                                                         }
                                                         // 6
                                                         else
                                                         {
                                                             // 7
                                                             if (error)
                                                             {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                                                                         message:@"There was an error retrieving your Facebook account, make sure you have an account setup in iSocial"
                                                                                                                        delegate:nil
                                                                                                               cancelButtonTitle:@"Dismiss"
                                                                                                               otherButtonTitles:nil];
                                                                     [alertView show];
                                                                 });
                                                             }
                                                             // 8 User deny access
                                                             else
                                                             {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                                                                         message:@"Access to Facebook was not granted. Please go to the device settings and allow access for iSocial"
                                                                                                                        delegate:nil
                                                                                                               cancelButtonTitle:@"Dismiss"
                                                                                                               otherButtonTitles:nil];
                                                                     [alertView show];
                                                                 });
                                                             }
                                                         }
         }];
    });
}

- (void)getPublishStream {
    // 1
    ACAccountType *facebookAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    __weak KidlendarAppDelegate *weakSelf = self;
    // 2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 3
        NSDictionary *facebookOptions = @{ACFacebookAppIdKey : @"1450548605159832",
                                          ACFacebookPermissionsKey : @[@"publish_stream"],
                                          ACFacebookAudienceKey : ACFacebookAudienceFriends };
        // 4
        [weakSelf.accountStore requestAccessToAccountsWithType:facebookAccountType
                                                       options:facebookOptions completion:^(BOOL granted,
                                                                                            NSError *error) {
                                                           // 5
                                                           if (granted)
                                                           {
                                                               weakSelf.facebookAccount = [[weakSelf.accountStore accountsWithAccountType:facebookAccountType]lastObject];
                                                               
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   [[NSNotificationCenter defaultCenter] postNotificationName:AccountFacebookAccountAccessGranted object:nil];
                                                               });
                                                           }
                                                           // 6
                                                           else
                                                           {
                                                               // 7
                                                               if (error)
                                                               {
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       UIAlertView *alertView = [[UIAlertView alloc]
                                                                                                 initWithTitle:@"Facebook"
                                                                                                 message:@"There was an error retrieving your Facebook account, make sureyou have an account setup in Settings and that access is granted foriSocial"
                                                                                                 delegate:nil
                                                                                                 cancelButtonTitle:@"Dismiss"
                                                                                                 otherButtonTitles:nil];
                                                                       [alertView show];
                                                                   });
                                                               }
                                                               // 8
                                                               else
                                                               {
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       UIAlertView *alertView = [[UIAlertView alloc]
                                                                                                 initWithTitle:@"Facebook"
                                                                                                 message:@"Access to Facebook was not granted. Please go to the device settings and allow access for iSocial"
                                                                                                 delegate:nil
                                                                                                 cancelButtonTitle:@"Dismiss"
                                                                                                 otherButtonTitles:nil];
                                                                       [alertView show];
                                                                   });
                                                               }
                                                           }
                                                       }];
    });
}

- (void)presentErrorWithMessage:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:errorMessage
                              delegate:nil
                              cancelButtonTitle:@"Dismiss"
                              otherButtonTitles:nil];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [alertView show];
    });
}

- (void)createAllViewControllers
{
    NSMutableArray *allCalendars = [[NSMutableArray alloc]initWithArray:[[[CalendarStore sharedStore]eventStore] calendarsForEntityType:EKEntityTypeEvent]];
    
    for (EKCalendar *c in allCalendars) {
            if (c.source.sourceType== EKSourceTypeCalDAV) {
            [[[CalendarStore sharedStore]allCalendars] addObject:c];
        }
    }
    
    for (EKCalendar *c in allCalendars) {
        if (c.type == EKCalendarTypeBirthday) {
            [[[CalendarStore sharedStore]allCalendars] addObject:c];
        }
    }
    
    [[CalendarStore sharedStore]setCalendar:[CalendarStore sharedStore].allCalendars[0]];

    // Set up calendar controller
    MonthViewController *calendarController = [[MonthViewController alloc]init];
    UINavigationController *calendarNavigationController = [[UINavigationController alloc]initWithRootViewController:calendarController];
    calendarNavigationController.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"Calendar" image:[UIImage imageNamed:@"calendarTab.png"] selectedImage:[UIImage imageNamed:@"calendarTab.png"]];
    
    // Set up diary controller
    DiaryTableViewController *diaryController = [[DiaryTableViewController alloc]init];
    UINavigationController *diaryNavigationController = [[UINavigationController alloc]initWithRootViewController:diaryController];
    diaryNavigationController.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"Moments" image:[UIImage imageNamed:@"diaryTab.png"] selectedImage:[UIImage imageNamed:@"diaryTab.png"]];
    
    // Set up setting controller
    SettingViewController *settingController = [[SettingViewController alloc]init];
    UINavigationController *settingNavigationController = [[UINavigationController alloc]initWithRootViewController:settingController];
    settingNavigationController.tabBarItem = [[UITabBarItem alloc]initWithTitle:@"Setting" image:[UIImage imageNamed:@"settingTab.png"] selectedImage:[UIImage imageNamed:@"settingTab.png"]];
    
    
    // Set up tab bar contoller for entire app
    tbc = [[UITabBarController alloc]init];
    NSArray *viewControllers = [NSArray arrayWithObjects:calendarNavigationController,diaryNavigationController,settingNavigationController, nil];
    [tbc setViewControllers:viewControllers];
    
    // Add Tab bar controller to window
    [[self window]setRootViewController:tbc];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"KidlendarModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"store.data"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
