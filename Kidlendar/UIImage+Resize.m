//
//  UIImage+Resize.m
//  Kidlendar
//
//  Created by Jack Yeh on 2013/12/24.
//  Copyright (c) 2013年 MarriageKiller. All rights reserved.
//

#import "UIImage+Resize.h"
#import "GPUImage.h"

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

    // Create a bitmap context.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), YES, [UIScreen mainScreen].scale);
    [self drawInRect:CGRectMake(0,0,newWidth,newHeight)];
    UIImage* finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
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
    // draw a CI image with the previously loaded face detection picture
    CIImage *o_image =  [CIImage imageWithCGImage:self.CGImage];
    NSLog(@"CIImage extent before transform %@",o_image);
    CGFloat xRatio = self.size.width/o_image.extent.size.width;
    CGFloat yRatio = self.size.height/o_image.extent.size.height;
    CGAffineTransform t = CGAffineTransformMakeScale(xRatio, yRatio);
    CIImage *image = [o_image imageByApplyingTransform:t];
    NSLog(@"CIImage extent after transform %@",image);
    
    CGFloat imageWidth = self.size.width;
    CGFloat imageHeight = self.size.height;
    
    CGFloat cropRatio = size.width/size.height;
    CGFloat maxCropHeight = imageWidth/cropRatio;
    CGFloat maxCropWidth = imageWidth;
    
    if (maxCropHeight > imageHeight) {
        maxCropHeight = imageHeight;
        maxCropWidth = imageHeight*cropRatio;
    }
    
    NSMutableArray *facesBounds = [[NSMutableArray alloc]init];
    
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    // create an array containing all the detected faces from the detector
    NSArray* features = [detector featuresInImage:image];
    
    NSLog(@"Image width %f height %f",imageWidth,imageHeight);
    NSLog(@"crop width %f , crop height = %f",maxCropWidth,maxCropHeight);
    
    
    if ([features count]==0) {
        CGFloat y = (imageHeight - maxCropHeight)/2;
        CGFloat x = (imageWidth - maxCropWidth)/2;
        CGRect cropRect = CGRectMake(x, y, maxCropWidth, maxCropHeight);

        return [self cropImageWithRect:cropRect resize:size];
    }
    else {
        for(CIFaceFeature* faceFeature in features)
        {
            CGRect b = faceFeature.bounds;
            NSValue *v = [NSValue valueWithCGRect:b];
            [facesBounds addObject:v];
        }
        
        // Set up
        CGRect initialRect = [facesBounds[0] CGRectValue];
        CGFloat y = initialRect.origin.y;
        CGFloat x = (imageWidth - maxCropWidth)/2;
        CGFloat diagonalY = initialRect.origin.y+initialRect.size.height;
        //CGFloat diagonalX = initialRect.origin.x+initialRect.size.width;
        CGRect highestFaceBounds = initialRect;
        
        for(NSValue *v in facesBounds) {
            CGRect faceBounds = [v CGRectValue];
            NSLog(@"face rect %@",v);
            CGSize  faceSize = faceBounds.size;
            CGPoint faceOrigin = faceBounds.origin;
            CGPoint faceOriginDiagonal = CGPointMake(faceOrigin.x+faceSize.width, faceOrigin.y+faceSize.height);
            
            if (faceOrigin.y <y)
                y = faceOrigin.y;
            
            if (faceOriginDiagonal.y > diagonalY) {
                diagonalY = faceOriginDiagonal.y;
                highestFaceBounds = faceBounds;
            }
        }
        
        CGFloat sumFaceDetectHeight = diagonalY - y;
        NSLog(@"crop width %f , crop height = %f , detect height = %f",maxCropWidth,maxCropHeight,sumFaceDetectHeight);
        
        // If face detect rec > max crop height
        if (sumFaceDetectHeight > maxCropHeight) {
            
            // Y coordinate of highest face bounds height
            CGFloat highestFaceBoundsHeight_y = highestFaceBounds.origin.y + highestFaceBounds.size.height;
            NSLog(@"y %f highest y %f",y,highestFaceBoundsHeight_y);
            if (maxCropHeight > highestFaceBounds.size.height) {
                CGFloat offset = (maxCropHeight - highestFaceBounds.size.height)/2;
                // Place crop rect in face bound center if no touched image height
                if ((highestFaceBoundsHeight_y+offset) < imageHeight) {
                    y = highestFaceBounds.origin.y - offset;
                    NSLog(@"1");
                }
                else {
                    y = self.size.height - maxCropHeight;
                    NSLog(@"2");
                }
            }
            // Set the crop rect in the middle of face bounds
            else {
                y = highestFaceBounds.origin.y + ((highestFaceBounds.size.height-maxCropHeight)/2);
                NSLog(@"3");
            }
        } else {
            // If max crop rect exceeded image height , move crop rect down to make it within image height
            if ((imageHeight - y ) < maxCropHeight) {
                // position the crop rect in middle of face rect
                y = imageHeight - maxCropHeight;
                NSLog(@"4");
            }
            else if ((imageHeight - y ) > maxCropHeight) {
                CGFloat offset =  (maxCropHeight - sumFaceDetectHeight)/2;
                if ((y-offset) > 0)
                    y -= offset;
                else
                    y =0;
                NSLog(@"5");
            }
            else {
                y = imageHeight - maxCropHeight;
                NSLog(@"6");
            }
        }
        
        NSLog(@"final y %f",y);
        
        // Final rect from face detection
        CGRect CIfinalRect = CGRectMake(x,y,maxCropWidth,maxCropHeight);
        NSValue *ci = [NSValue valueWithCGRect:CIfinalRect];
        NSLog(@"CIRect%@",ci);
        
        // Convert CIImage coordinate to UIImage coordinate
        CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
        transform = CGAffineTransformTranslate(transform,0, -imageHeight);
        CGRect cropRect = CGRectApplyAffineTransform(CIfinalRect, transform);
        
        // Crop
        return [self cropImageWithRect:cropRect resize:size];
    }

}

- (UIImage *)cropImageWithRect:(CGRect)cropRect resize:(CGSize)size
{
    // Convert cropRect unit to cropRegion unit
    CGAffineTransform t = CGAffineTransformMakeScale(1.0f / self.size.width, 1.0f / self.size.height);
    CGRect cropRegion = CGRectApplyAffineTransform(cropRect, t);
    
    NSValue *c = [NSValue valueWithCGRect:cropRect];    
    NSLog(@"crop rect %@",c);
    
//    // Process the filtering
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc]init];
    cropFilter.cropRegion = cropRegion;
    UIImage *cropImage =  [cropFilter imageByFilteringImage:self];
    return cropImage;
}

@end
