//
//  DiaryViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/28.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "DiaryViewController.h"
#import "DiaryData.h"
#import "KidlendarAppDelegate.h"
#import <Social/Social.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "KidlendarAppDelegate.h"
#import "PhotoLoader.h"
#import "AFHTTPRequestOperation.h"
#import "UIImage+Resize.h"
#import "FileManager.h"

@interface DiaryViewController () <UIAlertViewDelegate,NSURLSessionTaskDelegate>
{
    UIBarButtonItem *backupButton;
    MPMoviePlayerViewController *videoPlayer;
    UIAlertView *preparingAlertView;
}
@property (weak, nonatomic) IBOutlet UIImageView *diaryPhoto;
@property (weak, nonatomic) IBOutlet UITextView *diaryDetailTextView;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekdayLabel;
@property (weak, nonatomic) IBOutlet UIImageView *twitterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weiboImageView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookImageView;
@property (weak, nonatomic) IBOutlet UIView *videoPlayView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;


@property (weak, nonatomic) IBOutlet UIView *uploadView;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@property (weak, nonatomic) IBOutlet UIImageView *locationTag;

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
    
    self.navigationItem.title = _diaryData.subject;

    // Do any additional setup after loading the view from its nib.
    _videoPlayView.layer.cornerRadius = _videoPlayView.frame.size.width/2;
    _videoPlayView.layer.borderWidth = 4.0f;
    _videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
    
    // Put that image onto the screen in our image view
    FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
    _diaryPhoto.image = [[fm loadCollectionImage] resizeImageToSize:_diaryPhoto.frame.size];
    if (_diaryData.diaryVideoThumbnail) {
        UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playVideo)];
        [_videoPlayView addGestureRecognizer:videoTap];
        _videoPlayView.hidden = NO;
        
    } else {
        _videoPlayView.hidden = YES;
    }

   _diaryDetailTextView.text = _diaryData.diaryText;
    _subjectLabel.text = _diaryData.subject;
    
    if (_diaryData.location.length > 0) {
        _locationLabel.text= _diaryData.location;
        _locationTag.hidden = NO;
    } else {
        _locationLabel.text= nil;
        _locationTag.hidden = YES;
    }
    NSDate *diaryDate = [NSDate dateWithTimeIntervalSinceReferenceDate:_diaryData.dateCreated];
    
    NSDateComponents *dateComp = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth|NSCalendarUnitYear|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:diaryDate];
    
    NSArray *monthArray = @[@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December"];

    NSDateFormatter *weekdayFormatter = [[NSDateFormatter alloc]init];
    weekdayFormatter.dateFormat = @"EEEE";
    
    _dateLabel.text = [NSString stringWithFormat:@"%@ %ld,%ld",[monthArray objectAtIndex: [dateComp month]-1],(long)[dateComp day],(long)[dateComp year]];
    _weekdayLabel.text  = [weekdayFormatter stringFromDate:diaryDate];
    
    // Share Photo
    UITapGestureRecognizer *twitterTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_twitterImageView addGestureRecognizer:twitterTap];
    UITapGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_weiboImageView addGestureRecognizer:weiboTap];
    UITapGestureRecognizer *facebookTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_facebookImageView addGestureRecognizer:facebookTap];
    
    if (_diaryData.diaryVideoPath) {
        _twitterImageView.hidden = YES;
        _weiboImageView.hidden = YES;
    }
}

- (void)playVideo
{
    [self playMovieWithURL:[NSURL URLWithString:_diaryData.diaryVideoPath]];
}

#pragma mark - Social share

- (void)showShareSheet:(UITapGestureRecognizer *)sender
{
    
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
    
    if (serviceType==SLServiceTypeFacebook && _diaryData.diaryVideoPath) {
        [self uploadVideoToFacebook];
    } else {
        //  Create an instance of the share Sheet
        SLComposeViewController *shareSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:
                                               serviceType]; // Service Type 有 Facebook/Twitter/微博 可以選
        
        shareSheet.completionHandler = ^(SLComposeViewControllerResult result) {
            switch(result) {
                    //  This means the user cancelled without sending the Tweet
                case SLComposeViewControllerResultCancelled:
                    break;
                    //  This means the user hit 'Send'
                case SLComposeViewControllerResultDone:
                    break;
            }
        };
        
        //  Set the initial body of the share sheet
        [shareSheet setInitialText:_diaryData.diaryText];
        
        //  分享照片
        FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
        if (![shareSheet addImage:[fm loadCollectionImage]]) {
            NSLog(@"Unable to add the image!");
        }
        
        //  Presents the share Sheet to the user
        [self presentViewController:shareSheet animated:NO completion:nil];
    }
}

#pragma mark - Video upload to Facebook

- (void)uploadVideoToFacebook
{
    KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    if (appDelegate.facebookAccount)
    {
        [self proceedVideoUploadToFB];
    }
    else
    {
        UIAlertView *loginAlert = [[UIAlertView alloc]initWithTitle:@"Please login your Facebook account"
                                                            message:@"Click OK button to proceed login"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"OK", nil];
        
        [loginAlert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [appDelegate getFacebookAccount];
    }
}

- (void)proceedVideoUploadToFB
{
    _uploadView.hidden = NO;
    __block SLRequest *facebookRequest;
    __block NSData *data;
    NSDictionary *params = @{@"title": _diaryData.subject,
                             @"description": _diaryData.diaryText};
    
    [[PhotoLoader defaultAssetsLibrary] assetForURL:[NSURL URLWithString:_diaryData.diaryVideoPath] resultBlock:^(ALAsset *asset) {
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_t group = dispatch_group_create();

        dispatch_group_async(group, queue, ^{
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
            data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        });
        
        dispatch_group_notify(group, queue, ^{
            
            facebookRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                 requestMethod:SLRequestMethodPOST
                                                           URL:[NSURL URLWithString:@"https://graph.facebook.com/me/videos"]
                                                    parameters:params];
            
            [facebookRequest addMultipartData:data
                                     withName:@"source"
                                         type:@"video/quicktime"
                                     filename:@"test1.mov"];
            
            KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            
            
            facebookRequest.account = appDelegate.facebookAccount;
            
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:facebookRequest.preparedURLRequest];
            [operation setUploadProgressBlock:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    float uploadProgress = totalBytesWritten/(float)totalBytesExpectedToWrite;
                    [_progress setProgress:uploadProgress animated:YES];
                });

            }];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                _uploadView.hidden = YES;

                NSLog(@"Facebook upload success");
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                _uploadView.hidden = YES;

                NSLog(@"Facebook upload error %@",error);
            }];
            
            [operation start];
            
            
            [facebookRequest performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error) {
                if (error) {
                    // 4
                    KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                    [appDelegate presentErrorWithMessage:[NSString
                                                          stringWithFormat:@"There was an error uploading media. %@",
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
                                                              stringWithFormat:@"There was an error uploading media. %@",
                                                              [error localizedDescription]]];
                    } else {
                        NSLog(@"Response data %@",responseJSON);
                    }
                }
            }];

        });
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Converting error %@",error);
    }];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    self.tabBarController.tabBar.hidden = YES;
//}
//
//- (void)viewWillDisappear:(BOOL)animated
//{
//    self.tabBarController.tabBar.hidden = NO;
//}

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
