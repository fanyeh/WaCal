//
//  UIImage+Resize.h
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)
- (UIImage *)resizeImageToSize:(CGSize)newSize;
- (UIImage *)transformOrientationForSave;
- (UIImage *)resizeWtihFaceDetect:(CGSize)size;
@end
