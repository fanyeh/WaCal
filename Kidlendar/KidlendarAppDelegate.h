//
//  KidlendarAppDelegate.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/6.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

extern NSString *const AccountFacebookAccountAccessGranted;
extern NSString *const AccountTwitterAccountAccessGranted;



#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <FacebookSDK/FacebookSDK.h>
@import Accounts;
@import Social;

@interface KidlendarAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong,nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *facebookAccount;
@property (strong, nonatomic) ACAccount *twitterAccount;
- (void)getFacebookAccount;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;
- (void)userLoggedIn;
- (void)userLoggedOut;

- (void)presentErrorWithMessage:(NSString *)errorMessage;

@end
