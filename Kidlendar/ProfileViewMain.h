//
//  ProfileViewMain.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/13.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileData.h"
#import "customLabel.h"

@interface ProfileViewMain : UIView

@property UIImageView *picture;
@property customLabel *name;
@property customLabel *birthday;
@property customLabel *weight;
@property customLabel *height;
@property customLabel *gender;

- (id)initWithFrame:(CGRect)frame andProfile:(ProfileData *)profile;
@end
