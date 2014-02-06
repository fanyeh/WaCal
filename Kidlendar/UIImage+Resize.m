//
//  UIImage+Resize.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)
- (UIImage *)resizeImageToSize:(CGSize)newSize
{
    // Put that image onto the screen in our image view
    float hfactor = self.size.width / newSize.width;
    float vfactor = self.size.height /newSize.height;
    
    float factor = fmax(hfactor, vfactor);
    factor = fmaxf(factor, 1);
    
    // Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = self.size.width / factor;
    float newHeight = self.size.height / factor;

    
    CGRect rect = CGRectMake(0.0, 0.0, newWidth, newHeight);
    UIGraphicsBeginImageContext(rect.size);
    [self drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

- (UIImage *)transformOrientationForSave
{
    UIImage *image = self;
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

-(UIImage *)resizeWtihFaceDetect:(CGSize)size
{
    CGFloat displayViewRatio = size.width/size.height;
    CGFloat finalHeight = self.size.width/displayViewRatio;
    CGFloat finalWidth = self.size.width;

    // draw a CI image with the previously loaded face detection picture
    CIImage* image =  [CIImage imageWithCGImage:self.CGImage];
    
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    // create an array containing all the detected faces from the detector
    NSArray* features = [detector featuresInImage:image];
    float x = 0;
    float y = 0;
    float x1 = 0;
    float y1 = 0;
    int i =0;
    
    if (!features) {
        return [self resizeImageToSize:size];
    }
    else {
        for(CIFaceFeature* faceFeature in features)
        {
            CGRect b = faceFeature.bounds;
            if (i ==0 ) {
                x = b.origin.x;
                y = b.origin.y;
                if (b.origin.x + b.size.width > x1)
                    x1 = b.origin.x + b.size.width;
                if (b.origin.y + b.size.height > y1)
                    y1 = b.origin.y + b.size.height;
                
            }
            else {
                if (b.origin.x < x)
                    x = b.origin.x;
                if (b.origin.y < y)
                    y = b.origin.y;
                if (b.origin.x + b.size.width > x1)
                    x1 = b.origin.x + b.size.width;
                if (b.origin.y + b.size.height > y1)
                    y1 = b.origin.y + b.size.height;
            }
            i++;
        }
        float cropHeight = y1 - y;
        
        float remainHeightTop = self.size.height - y1;
        float remainHeightFromCrop = finalHeight - cropHeight;
        float remainHeightBot ;
        
        if (remainHeightFromCrop/2 > remainHeightTop)
            remainHeightBot = remainHeightFromCrop - remainHeightTop;
        else
            remainHeightBot = remainHeightTop/2;
        
        y = y - remainHeightBot;
        
        CGRect finalRect = CGRectMake(0,y,finalWidth,finalHeight);
        CIImage *rawImg = [CIImage imageWithCGImage:self.CGImage];
        CIImage *imageRef  = [rawImg imageByCroppingToRect:finalRect];
        UIImage *finalImage = [UIImage imageWithCIImage:imageRef];
        return [finalImage resizeImageToSize:size];
    }
}

@end
