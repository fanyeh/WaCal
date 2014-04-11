//
//  PhotoLayout.h
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoLayout : NSObject

@property (strong,nonatomic) NSMutableArray *allLayouts;

-(id)initWithSize:(CGSize)size andLineSpace:(CGFloat)line andCellSpace:(CGFloat)cell;
-(NSDictionary *)layoutBySelectionIndex:(NSInteger)index photoCount:(NSInteger)count;

@end
