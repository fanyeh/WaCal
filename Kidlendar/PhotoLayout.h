//
//  PhotoLayout.h
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoLayout : NSObject
@property (nonatomic) CGFloat lineSpace;
@property (nonatomic) CGFloat cellSpace;

-(id)initWithSize:(CGSize)size;
-(NSMutableArray *)layoutBySelectionIndex:(NSInteger)index photoCount:(NSInteger)count;

@end
