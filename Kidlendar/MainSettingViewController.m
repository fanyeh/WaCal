//
//  MainSettingViewController.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/6/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "MainSettingViewController.h"
#import "SettingViewController.h"
#import <StoreKit/StoreKit.h>
#import "Reachability.h"

@interface MainSettingViewController () <SKStoreProductViewControllerDelegate>

{
    BOOL chineseLang;
}

@end

@implementation MainSettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0],NSFontAttributeName,
                          [UIColor whiteColor],NSForegroundColorAttributeName,nil];
    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationItem.title = NSLocalizedString(@"Setting", nil);
    
    self.tableView.tintColor = MainColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];

    if ([language isEqualToString:@"zh-Hans"] || [language isEqualToString:@"zh-Hant"]) {
        chineseLang = YES;
    } else
        chineseLang = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        if (chineseLang)
            return 3;
        else
            return 2;
    }
    else
        return  1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell1"];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell1"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
        cell.textLabel.textColor = [UIColor colorWithWhite:0.400 alpha:1.000];
        cell.detailTextLabel.textColor = MainColor;
        
        if (indexPath.row == 2 && indexPath.section == 0) {
            UISwitch *lunarSwitch = [[UISwitch alloc]initWithFrame:CGRectMake(259, 9, 51, 31)];
            [cell.contentView addSubview:lunarSwitch];
            [lunarSwitch addTarget:self action:@selector(setLunarCal:) forControlEvents:UIControlEventValueChanged];
            
            if([[NSUserDefaults standardUserDefaults]boolForKey:@"LunarCalendar"])
                [lunarSwitch setOn:YES];
            else
                [lunarSwitch setOn:NO];
        }

    }

    // Configure the cell...
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Visible Calendars",nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 1) {
            
            NSString *weekStart = [[NSUserDefaults standardUserDefaults]stringForKey:@"WeekStart"];
            if (weekStart == nil) {
                weekStart = @"Monday";
                [[NSUserDefaults standardUserDefaults]setObject:@"Monday" forKey:@"WeekStart"];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Week Start",nil);
            cell.detailTextLabel.text = NSLocalizedString(weekStart, nil);
            
        } else if (indexPath.row == 2) {
            
            cell.textLabel.text = NSLocalizedString(@"Lunar Calendar",nil);
            
        }
        
    } else {
        
        cell.textLabel.text = NSLocalizedString(@"Rate W&Cal",nil);
    }
    
    
    return cell;
}

- (void)setLunarCal:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults]setBool:sender.on forKey:@"LunarCalendar"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil userInfo:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 49;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        if (indexPath.row==0) {
            SettingViewController *settingController = [[SettingViewController alloc]init];
            [self.navigationController pushViewController:settingController animated:YES];
            
        } else if (indexPath.row == 1) {
            
            NSString *weekStart = [[NSUserDefaults standardUserDefaults]stringForKey:@"WeekStart"];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if ([weekStart isEqualToString:@"Monday"]) {
                
                [[NSUserDefaults standardUserDefaults]setObject:@"Sunday" forKey:@"WeekStart"];
                cell.detailTextLabel.text = NSLocalizedString(@"Sunday", nil);
                
                
            } else if ([weekStart isEqualToString:@"Sunday"]) {
                
                [[NSUserDefaults standardUserDefaults]setObject:@"Monday" forKey:@"WeekStart"];
                cell.detailTextLabel.text = NSLocalizedString(@"Monday", nil);;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"EKCalendarSwitch" object:nil userInfo:nil];
            
        }
    
    
    } else {
        
        if ([self checkInternetConnection]) {
            
            [[UINavigationBar appearance] setTintColor:[UIColor darkGrayColor]];
            SKStoreProductViewController *storeController = [[SKStoreProductViewController alloc] init];
            storeController.delegate = self;
            
            NSDictionary *productParameters = @{ SKStoreProductParameterITunesItemIdentifier :@"853506017"};
            
            [storeController loadProductWithParameters:productParameters completionBlock:^(BOOL result, NSError *error) {
                if (result) {
                    
                    [self.navigationController presentViewController:storeController animated:YES completion:nil];
                    
                }
            }];
        }

    }

}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)checkInternetConnection
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *noInternetAlert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"No Internet Connection", nil)
                                                                 message:NSLocalizedString(@"Check your internet connection and try again",nil)
                                                                delegate:self cancelButtonTitle:NSLocalizedString(@"Close",nil)
                                                       otherButtonTitles:nil, nil];
        [noInternetAlert show];
        return NO;
    } else {
        return YES;
    }
}

@end
