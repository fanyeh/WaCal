//
//  DiaryPageViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/19.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryPageViewController.h"
#import "DiaryViewController.h"
#import "DiaryData.h"
#import "DiaryDataStore.h"
#import "DiaryCreateViewController.h"

@interface DiaryPageViewController () <UIPageViewControllerDataSource,UIPageViewControllerDelegate>
{
    UIPageViewController *diaryPageViewController;
    NSMutableArray *modelArray;
    NSInteger titleIndex;
}

@end

@implementation DiaryPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    

    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self  action:@selector(createDiary)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    modelArray = [[DiaryDataStore sharedStore]allItems];
    
    diaryPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                                                         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    diaryPageViewController.delegate = self;
    diaryPageViewController.dataSource = self;
    
    DiaryViewController *contentViewController = [[DiaryViewController alloc] initWithNibName:@"DiaryViewController" bundle:nil];
    contentViewController.diaryData = _diaryData;
    NSArray *viewControllers = [NSArray arrayWithObject:contentViewController];
    [diaryPageViewController setViewControllers:viewControllers
                                 direction:UIPageViewControllerNavigationDirectionForward
                                  animated:NO
                                completion:nil];
    
    [self addChildViewController:diaryPageViewController];
    [self.view addSubview:diaryPageViewController.view];
    
    [diaryPageViewController didMoveToParentViewController:self];
    
    NSUInteger currentIndex = [modelArray indexOfObject:[contentViewController diaryData]];
    self.navigationItem.title = [NSString stringWithFormat:@"%ld/%ld",currentIndex+1,[modelArray count]];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

- (void)createDiary
{
    DiaryCreateViewController *createViewController = [[DiaryCreateViewController alloc]init];
    [self.navigationController pushViewController:createViewController animated:YES];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger currentIndex = [modelArray indexOfObject:[(DiaryViewController *)viewController diaryData]];
    if(currentIndex == 0)
    {
        return nil;
    }
    
    titleIndex =  currentIndex;
    DiaryViewController *contentViewController = [[DiaryViewController alloc] init];
    contentViewController.diaryData = [modelArray objectAtIndex:currentIndex - 1];
    return contentViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger currentIndex = [modelArray indexOfObject:[(DiaryViewController *)viewController diaryData]];

    if(currentIndex == modelArray.count-1)
    {
        return nil;
    }
    
    titleIndex =  currentIndex+2;
    DiaryViewController *contentViewController = [[DiaryViewController alloc] init];
    contentViewController.diaryData = [modelArray objectAtIndex:currentIndex + 1];
    return contentViewController;
}

#pragma mark - UIPageViewControllerDelegage

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
        self.navigationItem.title = [NSString stringWithFormat:@"%ld/%ld",titleIndex,[modelArray count]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
