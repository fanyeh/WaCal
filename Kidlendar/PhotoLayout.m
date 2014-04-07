//
//  PhotoLayout.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/7.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "PhotoLayout.h"

@implementation PhotoLayout
{
    CGFloat sizeWidth;
    CGFloat sizeHeight;
    NSMutableArray *layoutArray;
}

-(id)initWithSize:(CGSize)size
{
    self = [super init];
    if (self) {
        sizeWidth = size.width;
        sizeHeight = size.height;
    }
    
    return self;
}

-(NSMutableArray *)layoutBySelectionIndex:(NSInteger)index photoCount:(NSInteger)count
{
    switch (count) {
        case 1:
            return [self onePhotoLayout];
            break;
        case 2:
            return [self twoPhotoLayout:index];
            break;
        case 3:
            return [self threePhotoLayout:index];
            break;
        case 4:
            return [self fourPhotoLayout:index];
            break;
        case 5:
            return [self fivePhotoLayout:index];
            break;
        default:
            return nil;
            break;
    }
}

- (NSMutableArray *)onePhotoLayout
{
    return [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, sizeHeight)]]];
}

- (NSMutableArray *)twoPhotoLayout:(NSInteger)index
{
    switch (index)
    {
        case 1:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/2)]
                                                               ]];
            break;
        case 2:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, sizeHeight)]
                                                                 ]];
            break;
        case 3:
            // Horizontal
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3, sizeHeight)]
                                                                 ]];
            break;
        case 4:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth,(sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth,(sizeHeight - _lineSpace)/3)]
                                                                 ]];
            break;
        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;
}

- (NSMutableArray *)threePhotoLayout:(NSInteger)index
{
    switch (index)
    {
        case 1:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)]
                                                               ]];
            break;
        case 2:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/3)]
                                                                 ]];
            break;
        case 3:
            // Horizontal
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)]
                                                                 ]];
            break;
        case 4:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)]
                                                                 ]];
            break;
        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;
}

- (NSMutableArray *)fourPhotoLayout:(NSInteger)index
{
    switch (index)
    {
        case 1:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/2)]
                                                               ]];
            break;
        case 2:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)]
                                                                 ]];
            break;
        case 3:
            // Horizontal
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace*2)/3)]
                                                                 ]];
            break;
        case 4:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight - _lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/2)]
                                                                 ]];
            break;
        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;
}

- (NSMutableArray *)fivePhotoLayout:(NSInteger)index
{
    switch (index)
    {
        case 1:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*2)/3, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*2)/3, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*2)/3, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace)/2, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace)/2, (sizeHeight-_lineSpace)/2)]
                                                               ]];
            break;
        case 2:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace)/2)]
                                                                 ]];
            break;
        case 3:
            // Horizontal
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace)/2, (sizeHeight-_lineSpace*2)/3)]
                                                                 ]];

            break;
        case 4:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth-_cellSpace*3)/4, (sizeHeight-_lineSpace)/2)]
                                                                 ]];
            break;
        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;
}

@end
