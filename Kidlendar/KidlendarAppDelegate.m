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
#import <FacebookSDK/FacebookSDK.h>
#import "SettingViewController.h"
#import <Dropbox/Dropbox.h>
#import "DiaryCreateViewController.h"
#import "DropboxModel.h"

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]

@implementation KidlendarAppDelegate
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        // app already launched
        DBAccount  *account = [DBAccountManager sharedManager].linkedAccount;
        if (!account || !account.linked) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Dropbox"];

        } else {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Dropbox"];
        }
        
        if (FBSession.activeSession.state == FBSessionStateOpen
            || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Facebook"];

        } else {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Facebook"];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        // This is the first launch ever
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FaceDetection"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Dropbox"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Facebook"];

        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"hsvuk547mb46ady" secret:@"z0bw1iew9vssq6r"];
    [DBAccountManager setSharedManager:accountManager];
    
    // Init Calendar store
    [CalendarStore sharedStore];
    
    if ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]==EKAuthorizationStatusAuthorized) {
        [self createAllViewControllers];
    }
    else {
        [[[CalendarStore sharedStore]eventStore] requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [self createAllViewControllers];
            }
            else
                NSLog(@"need permission , error %@",error);
        }];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundColor:Rgb2UIColor(33, 138, 251)];
//    [[UINavigationBar appearance] setBarTintColor:Rgb2UIColor(33, 138, 251)]; //is the bar color
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]]; //is the buttons text color
    return YES;
}

- (void)createAllViewControllers
{
    [[CalendarStore sharedStore]setAllCalendars:[[[CalendarStore sharedStore]eventStore] calendarsForEntityType:EKEntityTypeEvent]];
    [[CalendarStore sharedStore]setCalendar:[CalendarStore sharedStore].allCalendars[0]];

    // Set up calendar controller
    MonthViewController *calendarController = [[MonthViewController alloc]init];
    UINavigationController *calendarNavigationController = [[UINavigationController alloc]initWithRootViewController:calendarController];
    [calendarNavigationController.tabBarItem setTitle:@"Calendar"];
    
    // Set up diary controller
    DiaryTableViewController *diaryController = [[DiaryTableViewController alloc]init];
    UINavigationController *diaryNavigationController = [[UINavigationController alloc]initWithRootViewController:diaryController];
    [diaryNavigationController.tabBarItem setTitle:@"Diary"];
    
    // Set up setting controller
    SettingViewController *settingController = [[SettingViewController alloc]init];
    UINavigationController *settingNavigationController = [[UINavigationController alloc]initWithRootViewController:settingController];
    [settingNavigationController.navigationBar.topItem setTitle:@"Setting"];
    [settingNavigationController.tabBarItem setTitle:@"Setting"];
    
    
    // Set up tab bar contoller for entire app
    UITabBarController *tbc = [[UITabBarController alloc]init];
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
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
    [FBSession.activeSession close];
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

#pragma mark - Facebook Session

/*
 * If we have a valid session at the time of openURL call, we handle
 * Facebook transitions by passing the url argument to handleOpenURL
 */
// Facebook
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    if ([sourceApplication isEqual: @"com.facebook.Facebook"]) {
     // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
    
    if ([sourceApplication isEqual: @"com.getdropbox.Dropbox"]) {
        DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
        if (account) {
            NSLog(@"App linked successfully!");
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Dropbox"];
            return YES;
        }
        return NO;
    }
    return NO;
}

//- (void)closeSession {
//    [FBSession.activeSession closeAndClearTokenInformation];
//}
#pragma mark - Facebook
// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Facebook"];
        // Show the user the logged-in UI
        [self userLoggedIn];
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Facebook"];
        // If the session is closed
        NSLog(@"Session closed");
        // Show the user the logged-out UI
        [self userLoggedOut];
    }
    
    // Handle errors
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [self showMessage:alertText withTitle:alertTitle];
                
                // For simplicity, here we just show a generic message for all other errors
                // You can learn how to handle other errors using our guide: https://developers.facebook.com/docs/ios/errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [self showMessage:alertText withTitle:alertTitle];
            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI
        [self userLoggedOut];
    }
}

// Show the user the logged-out UI
- (void)userLoggedOut
{
    // Set the button title as "Log in with Facebook"
//    UIButton *loginButton = [self.customLoginViewController loginButton];
//    [loginButton setTitle:@"Log in with Facebook" forState:UIControlStateNormal];
    
    // Confirm logout message
    [self showMessage:@"You're now logged out" withTitle:@""];
}

// Show the user the logged-in UI
- (void)userLoggedIn
{
    // Set the button title as "Log out"
//    UIButton *loginButton = self.customLoginViewController.loginButton;
//    [loginButton setTitle:@"Log out" forState:UIControlStateNormal];
    
    // Welcome message
    [self showMessage:@"You're now logged in" withTitle:@"Welcome!"];
    
}

// Show an alert message
- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK!"
                      otherButtonTitles:nil] show];
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
