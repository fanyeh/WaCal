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
    UIColor *layoutColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        layoutLayer = [CAShapeLayer layer];
        CGRect contentFrame = self.contentView.frame;
        layoutView = [[UIView alloc]initWithFrame:CGRectMake(contentFrame.origin.x+12, contentFrame.origin.y+12, contentFrame.size.width-24, contentFrame.size.height-24)];
        [layoutView.layer addSublayer:layoutLayer];
        [self.contentView addSubview:layoutView];
        layoutColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    }
    return self;
}

- (void)drawLayoutWithViewSize:(CGSize)size andFrames:(NSArray *)frames andDirection:(UICollectionViewScrollDirection)direction
{
    CGRect layoutViewFrame = layoutView.frame;
    CGFloat originX = 0;
    CGFloat originY = 0;
    CGFloat cellWidth = layoutViewFrame.size.width;
    CGFloat cellHeight = layoutViewFrame.size.height;
    CGSize frameSize;
    CGSize previousFrameSize;
    CGMutablePathRef p1 = CGPathCreateMutable();
    CGAffineTransform t = CGAffineTransformMakeScale(cellWidth / (size.width-1), cellHeight / (size.height-1));

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
    layoutLayer.strokeColor = layoutColor.CGColor;
    layoutLayer.fillColor = [UIColor clearColor].CGColor;
    CGPathRelease(p1);
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        layoutColor = MainColor;
    }
    else {
        if (_isPhotoCountSection)
            layoutColor = [UIColor colorWithWhite:0.961 alpha:1.000];
        else
            layoutColor = [UIColor colorWithWhite:0.400 alpha:1.000];
    }
    layoutLayer.strokeColor = layoutColor.CGColor;
}

-(void)setIsPhotoCountSection:(BOOL)isPhotoCountSection
{
    if (isPhotoCountSection) {
        [self setUserInteractionEnabled: YES];
        if (self.isSelected)
            layoutColor = MainColor;
        else
            layoutColor = [UIColor colorWithWhite:0.961 alpha:1.000];
    }
    else {
        layoutColor = [UIColor colorWithWhite:0.400 alpha:1.000];
        [self setUserInteractionEnabled: NO];
    }
    
    _isPhotoCountSection = isPhotoCountSection;
}

@end
