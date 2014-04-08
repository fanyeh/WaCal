//
//  VideoView.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/8.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame deleteLabelSize:(NSInteger)size
{
    self = [super initWithFrame:frame];
    if (self) {
        _videoImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 316, 316)];
        _videoImageView.userInteractionEnabled  = YES;
        
        UIView *videoPlayView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 88, 88)];
        videoPlayView.layer.borderColor = [[UIColor whiteColor]CGColor];
        videoPlayView.layer.borderWidth = 3.0f;
        videoPlayView.layer.cornerRadius = videoPlayView.frame.size.width/2;
        videoPlayView.center = _videoImageView.center;
        videoPlayView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
        [_videoImageView addSubview:videoPlayView];
        
        UIImageView *playButtonView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
        playButtonView.image = [UIImage imageNamed:@"playButton.png"];
        playButtonView.center = _videoImageView.center;
        playButtonView.frame = CGRectOffset(playButtonView.frame, 5, 0);
        [_videoImageView addSubview:playButtonView];
        
        _videoDeleteLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width-size-5, 5, size, size)];
        _videoDeleteLabel.backgroundColor = [UIColor redColor];
        _videoDeleteLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
        _videoDeleteLabel.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
        _videoDeleteLabel.text = @"X";
        _videoDeleteLabel.textColor = MainColor;
        _videoDeleteLabel.textAlignment = NSTextAlignmentCenter;
        _videoDeleteLabel.layer.borderColor = [MainColor CGColor];
        _videoDeleteLabel.layer.borderWidth = 2.0f;
        _videoDeleteLabel.layer.cornerRadius = _videoDeleteLabel.frame.size.width/2;
        _videoDeleteLabel.hidden = YES;
        _videoDeleteLabel.userInteractionEnabled = YES;
        _videoDeleteLabel.layer.masksToBounds = YES;
        
        [self addSubview:_videoImageView];
        [self addSubview:_videoDeleteLabel];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
