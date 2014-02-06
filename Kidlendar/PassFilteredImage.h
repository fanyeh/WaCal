//
//  PassFilteredImage.h
//  Kidlendar
//
//  Created by Jack Yeh on 2014/1/28.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PassFilteredImage <NSObject>
@required
- (void)filteredImage:(UIImage *)image index:(NSInteger)i;

@end
