//
//  FacebookModel.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/18.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "FacebookModel.h"
#import "KidlendarAppDelegate.h"
#import "DiaryData.h"

@implementation FacebookModel

+ (FacebookModel *)shareModel
{
    static FacebookModel *shareModel = nil;
    if(!shareModel)
        shareModel = [[super allocWithZone:nil] init];
    
    return shareModel;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self shareModel];
}

- (id)init
{
    self = [super init];
    if(self) {
        
    }
    return self;
}

- (void)startFacebookSession
{
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        
        // If the session state is not any of the two "open" states when the button is clicked
    } else {
        // Open a session showing the user the login UI
        // You must ALWAYS ask for basic_info permissions when opening a session
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
             
             // Retrieve the app delegate
             KidlendarAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             [appDelegate sessionStateChanged:session state:state error:error];

         }];
    }
}

// We will post on behalf of the user, these are the permissions we need:
//NSArray *permissionsNeeded = @[@"publish_actions"];
//NSArray *permissionsNeeded = @[@"user_birthday",@"friends_hometown", @"friends_birthday",@"friends_location"];



- (void)ShareWithAPICalls:(NSArray *)permissionsNeeded action:(ActionType)actionType requestPermissionType:(PermissionType)permissionType
{
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded){
                                      if (![currentPermissions objectForKey:permission]) {
                                          [requestPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // If we have permissions to request
                                  if ([requestPermissions count] > 0){
                                      
                                      // Ask for the missing permissions
                                      if (permissionType==kPermissionTypePublish) {
                                          [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                                defaultAudience:FBSessionDefaultAudienceOnlyMe
                                                                              completionHandler:^(FBSession *session, NSError *error) {
                                                                                  if (!error) {
                                                                                      // Permission granted, we can request the user information
                                                                                      [self executeAction:actionType];
                                                                                  }
                                                                                  else {
                                                                                      // An error occurred, handle the error
                                                                                      // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                                                                      NSLog(@"%@", error.description);
                                                                                  }
                                                                              }];
                                      }

                                      else if (permissionType==kPermissionTypeRead) {
                                          [[FBSession activeSession]requestNewReadPermissions:requestPermissions
                                                                            completionHandler:^(FBSession *session, NSError *error) {
                                                                                if (!error) {
                                                                                    // Permission granted, we can request the user information
                                                                                    [self executeAction:actionType];
                                                                                }
                                                                                else {
                                                                                    // An error occurred, handle the error
                                                                                    // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                                                                    NSLog(@"%@", error.description);
                                                                                }
                                                                                
                                                                            }];

                                      }
                                  }
                                  else {
                                      // Permissions are present, we can request the user information
                                      [self executeAction:actionType];
                                  }
                              }
                              else {
                                  // There was an error requesting the permission information
                                  // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"%@", error.description);
                              }
                          }];
}

- (void)executeAction:(ActionType)type
{
    switch (type) {
        case kActionTypeShareLink:
            [self shareLink];
            break;
        case kActionTypeSharePhoto:
            [self sharePhoto];
            break;
        case kActionTypeFriendsBirthday:
            [self getFriendBirthday];
            break;
            
        default:
            break;
    }
}

- (void)shareLink {
    
    // NOTE: pre-filling fields associated with Facebook posts,
    // unless the user manually generated the content earlier in the workflow of your app,
    // can be against the Platform policies: https://developers.facebook.com/policy
    
    // Put together the dialog parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Sharing Tutorial", @"name",
                                   @"Build great social apps and get more installs.", @"caption",
                                   @"Allow your users to share stories on Facebook from your app using the iOS SDK.", @"description",
                                   @"https://developers.facebook.com/docs/ios/share/", @"link",
                                   @"http://i.imgur.com/g3Qc1HN.png", @"picture",
                                   nil];
    
    // Make the request
    [FBRequestConnection startWithGraphPath:@"/me/feed"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  // Link posted successfully to Facebook
                                  NSLog(@"result: %@", result);
                              } else {
                                  // An error occurred, we need to handle the error
                                  // See: https://developers.facebook.com/docs/ios/errors
                                  NSLog(@"%@", error.description);
                              }
                          }];
}

- (void)sharePhoto
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:_diaryData.diaryText, @"message",_diaryData.diaryImageData, @"picture", nil];
    
    [FBRequestConnection startWithGraphPath:@"me/photos"
                                 parameters:params
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              NSString *alertText;
                              if (error) {
                                  alertText = [NSString stringWithFormat:@"error: domain = %@, code = %ld",error.domain, (long)error.code];
                                  NSLog(@"error: %@", error);
                              } else {
                                  alertText = [NSString stringWithFormat:@"Posted action, id: %@",[result objectForKey:@"id"]];
                                  NSLog(@"result: %@", result);
                              }
                              // Show the result in an alert
                              [[[UIAlertView alloc] initWithTitle:@"Result"
                                                          message:alertText
                                                         delegate:self
                                                cancelButtonTitle:@"OK!"
                                                otherButtonTitles:nil]
                               show];
                          }];
}

- (void)getFriendList
{
    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        NSArray* friends = [result objectForKey:@"data"];
        NSLog(@"Found: %ld friends", (unsigned long)friends.count);
        for (NSDictionary<FBGraphUser>* friend in friends) {
            NSLog(@"I have a friend named %@ with id %@", friend.name, friend.id);
        }
    }];
}

- (void)getFriendBirthday
{
    FBRequest *friendRequest = [FBRequest requestForGraphPath:@"me/friends?fields=name,picture,birthday,location"];
    [friendRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSArray *data = [result objectForKey:@"data"];
        for (FBGraphObject<FBGraphUser> *friend in data) {
            NSLog(@"%@:%@", [friend name],[friend birthday]);
    }}];
}

@end
