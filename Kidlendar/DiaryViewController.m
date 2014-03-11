//
//  DiaryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryViewController.h"
#import "DiaryData.h"
#import <FacebookSDK/FacebookSDK.h>
#import "KidlendarAppDelegate.h"
#import "FacebookModel.h"
#import <Social/Social.h>
//#import <Parse/Parse.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "KidlendarAppDelegate.h"

@interface DiaryViewController () <FBLoginViewDelegate>
{
    UIBarButtonItem *backupButton;
    UIBarButtonItem *shareButton;
    MPMoviePlayerViewController *videoPlayer;
    UIAlertView *preparingAlertView;
}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetailTextView;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekdayLabel;
@property (weak, nonatomic) IBOutlet UIView *popUpBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *backupView;
@property (weak, nonatomic) IBOutlet UIView *shareView;
@property (weak, nonatomic) IBOutlet UIImageView *dropboxImageView;
@property (weak, nonatomic) IBOutlet UIImageView *twitterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weiboImageView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookImageView;

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
    
    // Put that image onto the screen in our image view
    if (_diaryData.diaryVideoThumbnail) {
        _diaryPhoto.image = _diaryData.diaryVideoThumbnail;
        UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playVideo)];
        _diaryPhoto.userInteractionEnabled = YES;
        [_diaryPhoto addGestureRecognizer:videoTap];
        
    } else {
        _diaryPhoto.image = _diaryData.diaryImage;
    }

   _diaryDetailTextView.text = _diaryData.diaryText;
    _subjectLabel.text = _diaryData.subject;
    _locationLabel.text= _diaryData.location;
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:_diaryData.dateCreated];
    
    NSDateComponents *dateComp = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:diaryDate];
    
    NSArray *monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];

    NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
    
    _yearLabel.text = [NSString stringWithFormat:@"%ld",(long)[dateComp year]];
    _monthLabel.text = [monthArray objectAtIndex: [dateComp month]-1];
    NSInteger day = [dateComp day];
    _dateLabel.text = [NSString stringWithFormat:@"%ld",(long)[dateComp day]];
    if (day==1) {
        _dateLabel.text = [NSString stringWithFormat:@"%ld st",(long)[dateComp day]];
    }
    
    _weekdayLabel.text  = [weekdayFormatter stringFromDate:diaryDate];
    
    UIBezierPath *exclusionPathYear = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_yearLabel.bounds
                                                                                                fromView:_yearLabel]];
    UIBezierPath *exclusionPathDate = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_dateLabel.bounds
                                                                                                fromView:_dateLabel]];
    UIBezierPath *exclusionPathMonth = [UIBezierPath bezierPathWithRect:[_diaryDetailTextView convertRect:_monthLabel.bounds
                                                                                                 fromView:_monthLabel]];
    
    _diaryDetailTextView.textContainer.exclusionPaths = @[exclusionPathYear,exclusionPathDate,exclusionPathMonth];

    
    shareButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"share.png"] style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(showShare)];
    
    self.navigationItem.rightBarButtonItems = @[shareButton];
    
    _backupView.layer.cornerRadius = 10.0f;
    _shareView.layer.cornerRadius = 10.0f;
    
    // Share
    UITapGestureRecognizer *twitterTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_twitterImageView addGestureRecognizer:twitterTap];
    UITapGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_weiboImageView addGestureRecognizer:weiboTap];
    UITapGestureRecognizer *facebookTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_facebookImageView addGestureRecognizer:facebookTap];
    
}

- (void)playVideo
{
    [self playMovieWithURL:[NSURL URLWithString:_diaryData.diaryVideoPath]];
}

- (IBAction)cancelPopup:(id)sender
{
    [self cancelAction];
}

- (void)cancelAction
{
    _popUpBackgroundView.hidden = YES;
    _shareView.hidden = YES;
    _backupView.hidden = YES;
    backupButton.enabled = YES;
    shareButton.enabled = YES;
    self.navigationItem.hidesBackButton = NO;
}

- (void)showBackup
{
    _popUpBackgroundView.hidden = NO;
    _shareView.hidden = YES;
    _backupView.hidden = NO;
    backupButton.enabled = NO;
    shareButton.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
}

- (void)showShare
{
    _popUpBackgroundView.hidden = NO;
    _backupView.hidden = YES;
    _shareView.hidden = NO;
    backupButton.enabled = NO;
    shareButton.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
}

- (void)showShareSheet:(UITapGestureRecognizer *)sender
{
    [self cancelAction];
    KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *serviceType;
    switch (sender.view.tag) {
        case 0:
            serviceType = SLServiceTypeTwitter;
            break;
        case 1:
            serviceType = SLServiceTypeSinaWeibo;
            break;
        case 2:
            serviceType = SLServiceTypeFacebook;
            break;
        default:
            break;
    }
    
    if (appDelegate.facebookAccount)
    {
        NSData *mediaData = _diaryData.diaryImageData;

        NSDictionary *parameters = @{@"message": _diaryData.diaryText};

        
        SLRequest *facebookRequest = [SLRequest requestForServiceType:serviceType
                                                        requestMethod:SLRequestMethodPOST
                                                                  URL:[NSURL URLWithString:@"https://graph.facebook.com/me/photos"]
                                                           parameters:parameters];

        [facebookRequest addMultipartData:mediaData
                                 withName:@"picture"
                                     type:@"image/png"
                                 filename:nil];
        
        facebookRequest.account = appDelegate.facebookAccount;
        
        
        [facebookRequest performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error) {
            if (error) {
                // 4
                KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                [appDelegate presentErrorWithMessage:[NSString
                                                      stringWithFormat:@"There was an error reading your Facebook feed. %@",
                                                      [error localizedDescription]]];
            }
            else
            {
                // 5
                NSError *jsonError;
                NSDictionary *responseJSON = [NSJSONSerialization
                                              JSONObjectWithData:responseData
                                              options:NSJSONReadingAllowFragments
                                              error:&jsonError];
                if (jsonError) {
                      // 6
                      KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                      [appDelegate presentErrorWithMessage:[NSString
                                                            stringWithFormat:@"There was an error reading your Facebook feed. %@",
                                                            [error localizedDescription]]];
                } else {
                    NSLog(@"Response data %@",responseJSON);
                }
            }
        }];
    }
    else
    {
        [appDelegate getFacebookAccount];
    }
}

- (void)upload{
    NSURL *videourl = [NSURL URLWithString:@"https://graph.facebook.com/me/videos"];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"me" ofType:@"mov"];
    NSURL *pathURL = [[NSURL alloc]initFileURLWithPath:filePath isDirectory:NO];
    NSData *videoData = [NSData dataWithContentsOfFile:filePath];
    
    NSDictionary *params = @{
                             @"title": @"Me being silly",
                             @"description": @"Me testing the video upload to Facebook with the new system."
                             };
    
    SLRequest *uploadRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                  requestMethod:SLRequestMethodPOST
                                                            URL:videourl
                                                     parameters:params];
    [uploadRequest addMultipartData:videoData
                           withName:@"source"
                               type:@"video/quicktime"
                           filename:[pathURL absoluteString]];
    
    uploadRequest.account = self.facebookAccount;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Movie player
#pragma mark

-(void) playMovieWithURL: (NSURL*) theURL
{
    
    videoPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL: theURL];
    [videoPlayer.moviePlayer setContentURL:theURL];
    
    [videoPlayer.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:1.0]] timeOption:MPMovieTimeOptionExact];
    // Setup the player
    videoPlayer.moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    videoPlayer.moviePlayer.shouldAutoplay = NO;
    
    // Add Movie Player to parent's view
//    [videoPlayer.view setFrame:CGRectMake(2, 46, 316, 320)];
    videoPlayer.view.layer.borderColor = [[UIColor whiteColor]CGColor];
    videoPlayer.view.layer.borderWidth = 2.0f;
   [videoPlayer.moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
    
    videoPlayer.moviePlayer.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self presentMoviePlayerViewControllerAnimated:videoPlayer];

    
    // Register for the playback finished notification
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePreloadDidFinish:)
                                                   name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                 object: videoPlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePlayBackDidFinish:)
                                                   name: MPMoviePlayerPlaybackDidFinishNotification
                                                 object: videoPlayer.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerEvent:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:videoPlayer.moviePlayer];
    
    [videoPlayer.moviePlayer prepareToPlay];
    [videoPlayer.moviePlayer pause];
    [self launchPreparingAlertViewAlert];
}

#pragma mark Media Playback Notification Methods
-(void)moviePlayerEvent:(NSNotification*)aNotification
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
}


- (void) moviePreloadDidFinish:(NSNotification*)notification
{
    [self dismissPreparingAlert];
}

-(void) moviePlayBackDidFinish: (NSNotification*) aNotification
{
    MPMoviePlayerController* moviePlayer=[aNotification object];
    
    // UnRegister for the playback finished notification
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object: moviePlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMoviePlayerPlaybackDidFinishNotification
                                                  object: moviePlayer];
    
    // Remove from the parent's view
//    [moviePlayer.view removeFromSuperview];
    
    // Stop before release to workaround iOS's bug
    [moviePlayer stop];
}

#pragma mark -
#pragma mark preparingAlertView Methods

- (void) launchPreparingAlertViewAlert {
	// Launch Downloading Alert
	if(preparingAlertView!=nil)	// Don't need to launch again
		return;
	
	preparingAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Movie Preparing..."
                                                   delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
	
	UIActivityIndicatorView *waitView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	waitView.frame = CGRectMake(120, 50, 40, 40);
	[waitView startAnimating];
	
	[preparingAlertView addSubview:waitView];
	[preparingAlertView show];
}

- (void) dismissPreparingAlert {
	if(preparingAlertView!=nil)
	{
		// Dismiss Downloading alert
		[preparingAlertView dismissWithClickedButtonIndex:0 animated:YES];//important
		preparingAlertView=nil;
	}
}


@end
