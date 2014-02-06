//
//  DiaryVideoViewController.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/27.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "DiaryVideoViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface DiaryVideoViewController ()
{
    UIAlertView *preparingAlertView;
    MPMoviePlayerViewController *player;
}
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@end

@implementation DiaryVideoViewController

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
    [self playMovieWithURL:_asset.defaultRepresentation.url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) playMovieWithURL: (NSURL*) theURL {
    
    player = [[MPMoviePlayerViewController alloc] initWithContentURL: theURL];
    [player.moviePlayer requestThumbnailImagesAtTimes:@[[NSNumber numberWithFloat:1.0]] timeOption:MPMovieTimeOptionExact];
    // Setup the player
    player.moviePlayer.controlStyle = MPMovieControlStyleDefault;
    player.moviePlayer.shouldAutoplay = NO;
        
    // Add Movie Player to parent's view
    [player.view setFrame:CGRectMake(10, 100, 300, 300)];
    player.moviePlayer.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:player.view];
    
    
    // Register for the playback finished notification
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePreloadDidFinish:)
                                                   name: MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                 object: player.moviePlayer];
    [[NSNotificationCenter defaultCenter]   addObserver: self
                                               selector: @selector(moviePlayBackDidFinish:)
                                                   name: MPMoviePlayerPlaybackDidFinishNotification
                                                 object: player.moviePlayer];
    [player.moviePlayer prepareToPlay];
    [player.moviePlayer pause];
    [self launchPreparingAlertViewAlert];
}

#pragma mark Media Playback Notification Methods

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
    [moviePlayer.view removeFromSuperview];
    
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
