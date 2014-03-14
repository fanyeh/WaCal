//
//  LocationData.m
//  Kidlendar
//
//  Created by Jack Yeh on 2014/2/17.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "LocationData.h"

@implementation LocationData
@dynamic longitude;
@dynamic latitude;
@dynamic locationKey;
@dynamic orderingValue;
@dynamic locationAddress;
@dynamic locationIcon;
@dynamic locationIconData;
@dynamic locationName;
@dynamic reference;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    UIImage *locationIcon = [UIImage imageWithData:[self locationIconData]];
    [self setPrimitiveValue:locationIcon forKey:@"locationIcon"];
}

- (void)setLocatinoIconDataFromImage:(UIImage *)image
{
    [self setLocationIcon:image];
    NSData *locationIconData = UIImagePNGRepresentation(image);
    [self setLocationIconData:locationIconData];
}

@end
