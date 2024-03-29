//
//  LocationData.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LocationData : NSManagedObject
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@property (nonatomic) double orderingValue;
@property (nonatomic, strong) NSString *locationKey;
@property (nonatomic, strong) NSString *locationAddress;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) UIImage *locationIcon;
@property (nonatomic, strong) NSData *locationIconData;

- (void)setLocatinoIconDataFromImage:(UIImage *)image;


@end
