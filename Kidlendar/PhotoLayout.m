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
    UICollectionViewScrollDirection direction;
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

-(NSDictionary *)layoutBySelectionIndex:(NSInteger)index photoCount:(NSInteger)count
{
    NSMutableArray *layoutFrames;
    switch (count) {
        case 1:
            layoutFrames = [self onePhotoLayout];
            break;
        case 2:
            layoutFrames =  [self twoPhotoLayout:index];
            break;
        case 3:
            layoutFrames =  [self threePhotoLayout:index];
            break;
        case 4:
            layoutFrames =  [self fourPhotoLayout:index];
            break;
        case 5:
            layoutFrames =  [self fivePhotoLayout:index];
            break;
        default:
            break;
    }
    return [NSDictionary dictionaryWithObject:layoutFrames forKey:[NSNumber numberWithUnsignedInteger:direction]];
}

- (NSMutableArray *)onePhotoLayout
{
    layoutArray = [[NSMutableArray alloc]initWithArray:@[[NSValue valueWithCGSize:CGSizeMake(sizeWidth, sizeHeight)]]];
    direction = UICollectionViewScrollDirectionVertical;
    return layoutArray;

}

- (NSMutableArray *)twoPhotoLayout:(NSInteger)index
{
    direction = UICollectionViewScrollDirectionVertical;
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
            // Vertical
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
        case 5:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth,(sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth,(sizeHeight - _lineSpace)/3*2)]
                                                                 ]];
            break;
        case 6:
            // Horizontal
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3*2) , sizeHeight)]
                                                                 ]];
//            direction = UICollectionViewScrollDirectionHorizontal;
            
            break;

        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;

}

- (NSMutableArray *)threePhotoLayout:(NSInteger)index
{
    direction = UICollectionViewScrollDirectionVertical;

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
            direction = UICollectionViewScrollDirectionHorizontal;

            break;
        case 4:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)]
                                                                 ]];
            break;
        case 5:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth,(sizeHeight - _lineSpace)/3 )]
                                                                 ]];
            break;
        case 6:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/3)]
                                                                 ]];
            break;
        case 7:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, sizeHeight)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, sizeHeight)]
                                                                 ]];
            break;
        case 8:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)]
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
    direction = UICollectionViewScrollDirectionVertical;

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
            direction = UICollectionViewScrollDirectionHorizontal;

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
        case 5:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2,(sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)]
                                                                 ]];
            break;
        case 6:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)]
                                                                 ]];
            break;
        case 7:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3),(sizeHeight - _lineSpace*2)/3)]
                                                                 ]];
            break;
        case 8:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2,(sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3*2)]
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
    direction = UICollectionViewScrollDirectionVertical;

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
            direction = UICollectionViewScrollDirectionHorizontal;


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
        case 5:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)]
                                                                 ]];
            break;
        case 6:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/2, (sizeHeight-_lineSpace*2)/3)]
                                                                 ]];
            break;
        case 7:
            // Vertical
            layoutArray =[[NSMutableArray alloc]initWithArray: @[
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(sizeWidth, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight-_lineSpace*2)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace*2)/3, (sizeHeight-_lineSpace*2)/3)]
                                                                 ]];
            break;
        case 8:
            // Vertical
            layoutArray = [[NSMutableArray alloc]initWithArray:@[
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3*2, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake((sizeWidth - _cellSpace)/3-0.5, (sizeHeight - _lineSpace)/3*2)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)],
                                                                 [NSValue valueWithCGSize:CGSizeMake(floorf((sizeWidth - _cellSpace)/3), (sizeHeight - _lineSpace)/3)]
                                                                 ]];

            break;
        default:
            layoutArray = nil;
            break;
    }
    return layoutArray;
}

@end
