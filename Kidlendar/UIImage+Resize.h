//
//  UIImage+Resize.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CellImage;

@interface UIImage (Resize)
- (UIImage *)resizeImageToSize:(CGSize)newSize;
- (UIImage *)transformOrientationForSave;
- (UIImage *)cropWithFaceDetect:(CGSize)size;
- (UIImage *)cropWithoutFaceOutDetect:(CGSize)size;

@end
