//
//  LayoutCell.m
//  W&Cal
//
//  Created by Jack Yeh on 2014/4/8.
//  Copyright (c) 2014年 MarriageKiller. All rights reserved.
//

#import "LayoutCell.h"

@implementation LayoutCell
{
    CAShapeLayer *layoutLayer;
    UIView *layoutView;
    NSInteger lines;
    NSInteger spaces;
    CGSize diaryPhotoViewSize;
    NSArray *layoutFrames;
    UICollectionViewScrollDirection layoutDirection;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        layoutLayer = [CAShapeLayer layer];
        CGRect contentFrame = self.contentView.frame;
        layoutView = [[UIView alloc]initWithFrame:CGRectMake(contentFrame.origin.x+10, contentFrame.origin.y+10, contentFrame.size.width-20, contentFrame.size.height-20)];
        [layoutView.layer addSublayer:layoutLayer];
        [self.contentView addSubview:layoutView];
        _layoutColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    }
    return self;
}

- (void)drawLayoutWithViewSize:(CGSize)size andFrames:(NSArray *)frames andDirection:(UICollectionViewScrollDirection)direction
{
    diaryPhotoViewSize = size;
    layoutFrames = frames;
    layoutDirection = direction;
    
    CGRect layoutViewFrame = layoutView.frame;
    CGFloat originX = 0;
    CGFloat originY = 0;
    CGFloat cellWidth = layoutViewFrame.size.width;
    CGFloat cellHeight = layoutViewFrame.size.height;
    CGSize frameSize;
    CGSize previousFrameSize;
    CGMutablePathRef p1 = CGPathCreateMutable();
    CGAffineTransform t = CGAffineTransformMakeScale(cellWidth / (size.width-2), cellHeight / (size.height-2));

    for (int i = 0; i < frames.count ; i ++) {
        NSValue *v = frames[i];
        frameSize = [v CGSizeValue];
        frameSize.height += 2;
        frameSize.width += 2;
        frameSize = CGSizeApplyAffineTransform(frameSize, t) ;

        if (i > 0) {
            // Horizontal
            if (direction == UICollectionViewScrollDirectionHorizontal) {
                if (frameSize.height + originY > cellHeight) {
                    originY = 0;
                    originX += previousFrameSize.width;
                }
            } else { // Vertical
                // Move to next row
                if (frameSize.width + originX > cellWidth) {
                    originX = 0;
                    originY += previousFrameSize.height;
                }
            }
        }
        CGRect layoutFrame = CGRectMake(originX, originY, frameSize.width, frameSize.height);
        CGPathAddRect(p1, nil, layoutFrame);
        
        // Horizontal
        if (direction == UICollectionViewScrollDirectionHorizontal)
            originY += frameSize.height;
        // Vertical
        else {
            originX += frameSize.width;
        }

        previousFrameSize = frameSize;
    }
    
    // Create mask Path
    layoutLayer.path = p1;
    layoutLayer.lineJoin = kCALineJoinBevel;
    layoutLayer.lineWidth = 3.0f;
    layoutLayer.strokeColor = _layoutColor.CGColor;
    layoutLayer.fillColor = [UIColor clearColor].CGColor;
    CGPathRelease(p1);
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        _layoutColor = MainColor;
    }
    else {
        _layoutColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    }
    
    [self drawLayoutWithViewSize:diaryPhotoViewSize andFrames:layoutFrames andDirection:layoutDirection];
}


@end
