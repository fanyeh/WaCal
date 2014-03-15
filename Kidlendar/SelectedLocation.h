//
//  SelectedLocation.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/3/14.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SelectedLocation : NSObject
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic, strong) NSString *locationAddress;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSString *reference;
@end
