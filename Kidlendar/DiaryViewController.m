//
//  DiaryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryViewController.h"
#import "DiaryData.h"

@interface DiaryViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UILabel *diarySubject;

@end

@implementation DiaryViewController

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
    
    // Extend view from navigation bar
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Get photo from  use diary data key
    // Put that image onto the screen in our image view
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *diaryDirectory = [documentsDirectory stringByAppendingPathComponent:_diaryData.diaryKey];
    NSString *getImagePath = [diaryDirectory stringByAppendingPathComponent:@"collectionViewImage.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:getImagePath];
    _diaryPhoto.image = image;
    _diarySubject.text = _diaryData.subject;
    
    // TODO:Add swipe gesture , only swipable if there are more than 1 diaries
    // TODO:Add share button on navigation bar right
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
