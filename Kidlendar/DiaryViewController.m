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
#import "Dropbox.h"
#import "DBFile.h"

@interface DiaryViewController () <UIAlertViewDelegate,NSURLSessionTaskDelegate>
{
    UIBarButtonItem *backupButton;
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
@property (weak, nonatomic) IBOutlet UIImageView *dropboxImageView;
@property (weak, nonatomic) IBOutlet UIImageView *twitterImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weiboImageView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookImageView;

@property (nonatomic, strong) NSURLSessionUploadTask *uploadTask;
@property (nonatomic, strong) NSURLSession *session;
@property (weak, nonatomic) IBOutlet UIView *uploadView;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;


@end

@implementation DiaryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // 1
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        // 2
        [config setHTTPAdditionalHeaders:@{@"Authorization": [Dropbox apiAuthorizationHeader]}];
        
        // 3
        _session = [NSURLSession sessionWithConfiguration:config];
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
    
    _backupView.layer.cornerRadius = 10.0f;
    
    // Share Photo
    UITapGestureRecognizer *twitterTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_twitterImageView addGestureRecognizer:twitterTap];
    UITapGestureRecognizer *weiboTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_weiboImageView addGestureRecognizer:weiboTap];
    UITapGestureRecognizer *facebookTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showShareSheet:)];
    [_facebookImageView addGestureRecognizer:facebookTap];
    
    UITapGestureRecognizer *dropboxTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(uploadToDropbox)];
    [_dropboxImageView addGestureRecognizer:dropboxTap];
    
    if (_diaryData.diaryVideoPath) {
        _twitterImageView.hidden = YES;
        _weiboImageView.hidden = YES;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showBackup)];
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
    backupButton.enabled = YES;
    self.navigationItem.hidesBackButton = NO;
}

- (void)showBackup
{
    _popUpBackgroundView.hidden = NO;
    backupButton.enabled = NO;
    self.navigationItem.hidesBackButton = YES;
}

-(void)uploadToDropbox
{
    _popUpBackgroundView.hidden = YES;
    // 1. Check to see if have access token to dropbox
    NSString *token = [[NSUserDefaults standardUserDefaults] valueForKey:accessToken];
    if (token) {
        [self uploadImage:_diaryData.diaryImageData];
    } else {
        [self getOAuthRequestToken];
    }
}

// stop upload

- (IBAction)cancelUpload:(id)sender
{
    if (_uploadTask.state == NSURLSessionTaskStateRunning) {
        [_uploadTask cancel];
    }
}

- (void)uploadImage:(NSData *)imageData
{
    // 1
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 1;
    [config setHTTPAdditionalHeaders:@{@"Authorization": [Dropbox apiAuthorizationHeader]}];
    
    // 2
    NSURLSession *upLoadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    // for now just create a random file name, dropbox will handle it if we overwrite a file and create a new name..
    NSURL *url = [Dropbox createPhotoUploadURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    
    // 3
    self.uploadTask = [upLoadSession uploadTaskWithRequest:request fromData:imageData];
    
    // 4
    self.uploadView.hidden = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    // 5
    [_uploadTask resume];
}

- (void)downloadPhotos
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSString *photoDir = [NSString stringWithFormat:@"https://api.dropbox.com/1/search/dropbox/%@/photos?query=.jpg",appFolder];
    NSURL *url = [NSURL URLWithString:photoDir];
    
    [[_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
            if (httpResp.statusCode == 200) {
                NSError *jsonError;
                NSArray *filesJSON = [NSJSONSerialization
                                      JSONObjectWithData:data
                                      options:NSJSONReadingAllowFragments
                                      error:&jsonError];
                
                NSMutableArray *dbFiles = [[NSMutableArray alloc] init];
                
                if (!jsonError) {
                    for (NSDictionary *fileMetadata in filesJSON) {
                        DBFile *file = [[DBFile alloc]
                                        initWithJSONData:fileMetadata];
                        [dbFiles addObject:file];
                    }
                    
                    [dbFiles sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                        return [obj1 compare:obj2];
                    }];
                    
//                    _photoThumbnails = dbFiles;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//                        [self.tableView reloadData];
                    });
                }
            } else {
                // HANDLE BAD RESPONSE //
            }
        } else {
            // ALWAYS HANDLE ERRORS :-] //
        }
    }] resume];
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progress setProgress:
         (double)totalBytesSent /
         (double)totalBytesExpectedToSend animated:YES];
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    // 1
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        _uploadView.hidden = YES;
        backupButton.enabled = YES ;
    });
    
    if (!error) {
        // 2
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Upload completed");

        });
    } else {
        // Alert for error
    }
}

# pragma mark - OAUTH 1.0a STEP 1
-(void)getOAuthRequestToken
{
    // OAUTH Step 1. Get request token.
    [Dropbox requestTokenWithCompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
            if (httpResp.statusCode == 200) {
                
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                /*
                 oauth_token The request token that was just authorized. The request token secret isn't sent back.
                 If the user chooses not to authorize the application,
                 they will get redirected to the oauth_callback URL with the additional URL query parameter not_approved=true.
                 */
                NSDictionary *oauthDict = [Dropbox dictionaryFromOAuthResponseString:responseStr];
                // save the REQUEST token and secret to use for normal api calls
                [[NSUserDefaults standardUserDefaults] setObject:oauthDict[oauthTokenKey] forKey:requestToken];
                [[NSUserDefaults standardUserDefaults] setObject:oauthDict[oauthTokenKeySecret] forKey:requestTokenSecret];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                
                NSString *authorizationURLWithParams = [NSString stringWithFormat:@"https://www.dropbox.com/1/oauth/authorize?oauth_token=%@&oauth_callback=dropbox://userauthorization",oauthDict[oauthTokenKey]];
                
                // escape codes
                NSString *escapedURL = [authorizationURLWithParams stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                // opens to user auth page in safari
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:escapedURL]];
                
            } else {
                // HANDLE BAD RESPONSE //
                NSLog(@"unexpected response getting token %@",[NSHTTPURLResponse localizedStringForStatusCode:httpResp.statusCode]);
            }
        } else {
            // ALWAYS HANDLE ERRORS :-] //
        }
    }];
}


#pragma mark - Social share

- (void)showShareSheet:(UITapGestureRecognizer *)sender
{
    [self cancelAction];
    
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
        if (![shareSheet addImage:_diaryData.diaryImage]) {
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
    KidlendarAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate getFacebookAccount];
}

- (void)proceedVideoUploadToFB
{
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
                NSLog(@"%ld bytes out of %ld sent.", totalBytesWritten, totalBytesExpectedToWrite);
                float progress = totalBytesWritten/(float)totalBytesExpectedToWrite;
                NSLog(@"Progress :%f",progress);
            }];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
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

        });
        
    } failureBlock:^(NSError *error) {
        NSLog(@"Converting error %@",error);
    }];
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
