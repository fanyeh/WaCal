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
#import "Reachability.h"
#import "CircleProgressView.h"

#import "UploadStore.h"
#define MainColor [UIColor colorWithRed:(64 / 255.0) green:(98 / 255.0) blue:(124 / 255.0) alpha:1.0]


@interface DiaryViewController () <UIAlertViewDelegate,NSURLSessionTaskDelegate>
{
    UIBarButtonItem *backupButton;
    MPMoviePlayerViewController *videoPlayer;
    UIAlertView *preparingAlertView;
    __block long long videoSize;
    uint8_t *buffer;
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
@property (weak, nonatomic) IBOutlet CircleProgressView *circleProgressView;
@property (weak, nonatomic) IBOutlet UIImageView *locationTag;
@property (strong,nonatomic) NSURLSession *session;
@property (strong,nonatomic) NSURLSessionUploadTask *uploadTask;
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
    FileManager *fm = [[FileManager alloc]initWithKey:_diaryData.diaryKey];
    _diaryPhoto.image = [[fm loadCollectionImage] resizeImageToSize:_diaryPhoto.frame.size];
    
    // Setup if it's a video
    if (_diaryData.diaryVideoThumbnail) {
        _diaryPhoto.layer.borderColor = [[UIColor whiteColor]CGColor];
        _diaryPhoto.layer.borderWidth = 2.0f;
        UITapGestureRecognizer *videoTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playVideo)];
        _videoPlayView.layer.cornerRadius = _videoPlayView.frame.size.width/2;
        _videoPlayView.layer.borderWidth = 2.0f;
        _videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
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
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showUploadProgress:) name:@"uploadVideo" object:nil];
    
    UITapGestureRecognizer *progressTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelUpload)];
    [_circleProgressView addGestureRecognizer:progressTap];
    
    _facebookImageView.layer.cornerRadius = _facebookImageView.frame.size.width/4;
    _facebookImageView.layer.masksToBounds = YES;
    _twitterImageView.layer.cornerRadius = _twitterImageView.frame.size.width/4;
    _twitterImageView.layer.masksToBounds = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showUploadProgress:) name:@"uploadVideo" object:nil];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"uploadVideo" object:nil];
}
- (void)playVideo
{
    [self playMovieWithURL:[NSURL URLWithString:_diaryData.diaryVideoPath]];
}

- (void)showUploadProgress:(NSNotification *)notification
{
    NSString *diaryKey = [[notification userInfo]objectForKey:@"diaryKey"];
    if ([diaryKey isEqualToString:_diaryData.diaryKey]) {
        _circleProgressView.hidden = NO;
        _facebookImageView.hidden = YES;
        float uploadProgress = [[notification object] floatValue];
        [_circleProgressView updateProgress:uploadProgress];
    }
}

#pragma mark - Social share

- (void)showShareSheet:(UITapGestureRecognizer *)sender
{
    if ([self checkInternetConnection]) {
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
}

#pragma mark - Video upload to Facebook

- (void)uploadVideoToFacebook
{
    KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    if (appDelegate.facebookAccount)
    {
        _circleProgressView.hidden = NO;
        _facebookImageView.hidden = YES;
        [self proceedVideoUploadToFB];
    }
    else
    {
        UIAlertView *loginAlert = [[UIAlertView alloc]initWithTitle:nil
                                                            message:@"Click OK button to obtain Facebook access"
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
        [appDelegate getPublishStream];
    }
}

- (void)proceedVideoUploadToFB
{
    __block SLRequest *facebookRequest;
    __block NSData *data;
    
    if (!_diaryData.subject)
        _diaryData.subject = @"";
    if (!_diaryData.diaryText)
        _diaryData.diaryText = @"";
    
    NSDictionary *params = @{@"title": _diaryData.subject,
                             @"description": _diaryData.diaryText};
    
    [[PhotoLoader defaultAssetsLibrary] assetForURL:[NSURL URLWithString:_diaryData.diaryVideoPath] resultBlock:^(ALAsset *asset) {
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_t group = dispatch_group_create();

        dispatch_group_async(group, queue, ^{
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            buffer = (Byte*)malloc(rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
            data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:NO];
            videoSize = rep.size;
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
            data = nil;
            [self uploadVidoeWithNSURLSession:facebookRequest];
        });
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Converting error %@",error);
    }];
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float uploadProgress = (double)totalBytesSent / (double)videoSize;
        [[NSNotificationCenter defaultCenter]postNotificationName:@"uploadVideo" object:[NSString stringWithFormat:@"%f",uploadProgress] userInfo:@{@"diaryKey":_diaryData.diaryKey}];
    });
}
- (void)cancelUpload
{
    NSURLSessionUploadTask *task = [[[UploadStore sharedStore]allTasks] objectForKey:_diaryData.diaryKey];
    [task cancel];
    _circleProgressView.hidden = YES;
    _facebookImageView.hidden = NO;
    [[[UploadStore sharedStore]allTasks]removeObjectForKey:_diaryData.diaryKey];
    free(buffer);
    [[NSNotificationCenter defaultCenter]postNotificationName:@"diaryChange" object:nil];
}

- (void)uploadVidoeWithNSURLSession:(SLRequest *)request
{
    // 1
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 1;

    NSURLSession *upLoadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    self.uploadTask = [upLoadSession uploadTaskWithStreamedRequest:request.preparedURLRequest];
    
    [[[UploadStore sharedStore]allTasks] setValue:_uploadTask forKey:_diaryData.diaryKey];
    
    [_uploadTask resume];
}

-(void)uploadVidoeWithAFNetwork:(SLRequest *)facebookRequest
{
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:facebookRequest.preparedURLRequest];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            float uploadProgress = totalBytesWritten/(float)totalBytesExpectedToWrite;
            [[NSNotificationCenter defaultCenter]postNotificationName:@"uploadVideo" object:[NSString stringWithFormat:@"%f",uploadProgress] userInfo:@{@"diaryKey":_diaryData.diaryKey}];
        });
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:_diaryData.diaryKey object:nil];
        UIAlertView *loginAlert = [[UIAlertView alloc]initWithTitle:[NSString stringWithFormat:@"Diary is uploaded"]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        
        [loginAlert show];
        
        NSLog(@"Facebook upload success");
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    // 1
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    });
    
    if (!error) {
        // 2
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Upload completed");
            _circleProgressView.hidden = YES;
            _facebookImageView.hidden = NO;
            [[[UploadStore sharedStore]allTasks]removeObjectForKey:_diaryData.diaryKey];
            free(buffer);
            [[NSNotificationCenter defaultCenter]postNotificationName:@"diaryChange" object:nil];
        });
    } else {
        // Alert for error
        NSLog(@"Upload error %@",error);
    }
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
    videoPlayer.moviePlayer.shouldAutoplay = YES;
    
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

- (BOOL)checkInternetConnection
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *noInternetAlert = [[UIAlertView alloc]initWithTitle:nil message:@"No Internet Connection" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
        [noInternetAlert show];
        return NO;
    } else {
        return YES;
    }
}

@end
