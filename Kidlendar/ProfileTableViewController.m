//
//  ProfieStoreViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/11.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "ProfileTableViewController.h"
#import "ProfileDataStore.h"
#import "ProfileData.h"
#import "ProfileCreateViewController.h"
#import "ProfileViewController.h"
#import "profileCell.h"


@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController

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
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(addProfile)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self  action:@selector(editProfileTable)];
    self.navigationItem.leftBarButtonItem = editButton;
    
    [self.tableView registerClass:[profileCell class] forCellReuseIdentifier:@"ProfileCell"];

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[ProfileDataStore sharedStore]allItems ]count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProfileCell";
    profileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell)
    {
        cell = [[profileCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // Configure the cell...
    ProfileData *p = [[[ProfileDataStore sharedStore]allItems]objectAtIndex:[indexPath row]];
    cell.textLabel.text = p.name;
    cell.imageView.image = p.thumbnail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.profileData = p;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        ProfileData *p = [[[ProfileDataStore sharedStore]allItems]objectAtIndex:[indexPath row]];
        [[ProfileDataStore sharedStore] removeItem:p];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:NO animated:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(void)addProfile
{
    ProfileCreateViewController *createProfileController = [[ProfileCreateViewController alloc]init];
    createProfileController.profile = [[ProfileDataStore sharedStore] createItem];
    [self.navigationController pushViewController:createProfileController animated:YES];
}

-(void)editProfileTable
{
    [self setEditing:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProfileViewController *p = [[ProfileViewController alloc]init];
    p.profile = [ProfileDataStore sharedStore].allItems[indexPath.row];
    [self.navigationController pushViewController:p animated:YES];
}

@end
