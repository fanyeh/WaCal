//
//  Scroller.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/8.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "Scroller.h"

@implementation Scroller

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        // Scroll control for photo collection view
        self.backgroundColor = [UIColor blackColor];
        
        // Scroller for photo collection
        _scrollerBar = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width/2 - 15, 7, 30, 4)];
        _scrollerBar.backgroundColor = [UIColor whiteColor];
        _scrollerBar.layer.cornerRadius = 2;
        _scrollerBar.layer.masksToBounds = YES;
        [self addSubview:_scrollerBar];
        
        // Tool bar on scroller
        _toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 11 , 320, 44)];
        _toolBar.tintColor = [UIColor whiteColor];
        _layoutButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"layout.png"] style:UIBarButtonItemStylePlain target:nil action:nil];
        _layoutButton.enabled = NO;
        _albumNameButton = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStyleBordered target:nil action:nil];
        _photoButton = [[UIBarButtonItem alloc]initWithTitle:@"0/5" style:UIBarButtonItemStyleBordered target:nil action:nil];
        _photoButton.enabled = NO;
        UIBarButtonItem *flexButton1 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *flexButton2 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        _toolBar.items = @[_layoutButton,flexButton1,_albumNameButton,flexButton2,_photoButton];
        [_toolBar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [_toolBar setBackgroundColor:[UIColor blackColor]];
        [self addSubview:_toolBar];
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
