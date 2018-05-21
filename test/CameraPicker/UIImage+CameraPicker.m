//
//  UIImage+CameraPicker.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import MobileCoreServices;
#import "UIImage+CameraPicker.h"


@implementation UIImage (CameraPicker)

+ (UIImage *)camp_imageWithSize:(CGSize)size drawBlock:(DrawBlock)drawBlock {
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (drawBlock) drawBlock(context, size);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)camp_imageWithCameraPickerPhotoSize:(CameraPickerPhotoSize)photoSize forImageData:(NSData *)imageData {
    
    UIImage *resizedPhoto = nil;
    
    switch (photoSize) {
            
        case CameraPickerPhotoSizeOriginal:
            resizedPhoto = [UIImage imageWithData:imageData];
            break;
        case CameraPickerPhotoSizeMedium:
            resizedPhoto = [UIImage camp_resizedImageFromImageWithData:imageData subsampleFactor:4];
            break;
        case CameraPickerPhotoSizeSmall:
            resizedPhoto = [UIImage camp_resizedImageFromImageWithData:imageData subsampleFactor:8];
            break;
    }
    
    if (resizedPhoto) {
        return resizedPhoto;
    }
    
    NSLog(@"Unable to resize photo %@ for size: %ld", imageData, (long)photoSize);
    return nil;
}

- (UIImage *)camp_scaleImage:(CGFloat)scale {
    
    CGImageRef cgImage = self.CGImage;
    if (!cgImage) {
        NSLog(@"Unable to scale image with nil CGImage");
        return nil;
    }
    
    size_t width = CGImageGetWidth(cgImage) / self.scale * scale;
    size_t height = CGImageGetHeight(cgImage) / self.scale * scale;
    
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 width,
                                                 height,
                                                 CGImageGetBitsPerComponent(cgImage),
                                                 0,
                                                 CGImageGetColorSpace(cgImage),
                                                 CGImageGetBitmapInfo(cgImage));
    if (!context) {
        NSLog(@"Unable to scale image (could not create context)");
        return nil;
    }
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0, 0, width ,height), cgImage);
    CGImageRef cgResult = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    if (!cgResult) {
        NSLog(@"Unable to scale image");
        return nil;
    }
    
    UIImage *resizedImage = [[UIImage imageWithCGImage:cgResult scale:self.scale orientation:self.imageOrientation] copy];
    
    CGImageRelease(cgResult);
    return resizedImage;
}

- (UIImage *)camp_rotatedImageAccordingToImageOrientation {
    
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

#pragma mark - Type Conversions

- (BOOL)camp_writeJPEGToMemory:(NSMutableData **)memory withQuality:(double)quality {
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)*memory, kUTTypeJPEG, 1, NULL);
    if (!destination) {
        
        NSLog(@"Failed to create CGImageDestination for image: %@", self);
        return NO;
    }
    
    CGImagePropertyOrientation orientation = [UIImage camp_cgImagePropertyOrientationFromUIImageOrientation:self.imageOrientation];
    
    CFDictionaryRef properties = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [NSNumber numberWithDouble:quality], (__bridge NSString *)kCGImageDestinationLossyCompressionQuality,
                                                            [NSNumber numberWithUnsignedInteger:orientation], (__bridge NSString *)kCGImagePropertyOrientation,
                                                            nil];
    CGImageDestinationAddImage(destination, self.CGImage, properties);
    
    if (!CGImageDestinationFinalize(destination)) {
        
        NSLog(@"Failed to write image: %@ to CGImageDestination", self);
        CFRelease(destination);
        return NO;
    }
    CFRelease(destination);
    
    return YES;
}

#pragma mark - Zero-Copy Resize

+ (UIImage *)camp_resizedImageFromImageWithData:(NSData *)imageData subsampleFactor:(NSUInteger)subsampleFactor {
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObject:@NO
                                                                                    forKey:(__bridge NSString *)kCGImageSourceShouldCache];
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, options);
    if (!imageSource) {
        NSLog(@"Failed to create CGImageSource with data");
        return nil;
    }
    
    UIImage *resizedImage = [UIImage camp_resizedImageFromImageSource:imageSource subsampleFactor:subsampleFactor];
    CFRelease(imageSource);
    
    return resizedImage;
}

+ (UIImage *)camp_resizedImageFromImageSource:(CGImageSourceRef)imageSource subsampleFactor:(NSUInteger)subsampleFactor {
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                         @NO, (__bridge NSString *)kCGImageSourceShouldCache,
                                                         @YES, (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways,
                                                         [NSNumber numberWithUnsignedInteger:subsampleFactor], (__bridge NSString *)kCGImageSourceSubsampleFactor,
                                                         nil];
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)@{ (__bridge NSString *)kCGImageSourceShouldCache: @NO });
    NSNumber *orientationNumber = [imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyOrientation];
    CGImagePropertyOrientation orientation = orientationNumber.unsignedIntValue;
    UIImageOrientation imageOrientation = [UIImage camp_imageOrientationFromCGImagePropertyOrientation:orientation];
    
    UIImage *resizedImage = [UIImage imageWithCGImage:imgRef scale:1.0f orientation:imageOrientation];
    
    CGImageRelease(imgRef);
    
    return resizedImage;
}

#pragma mark - Utils

+ (UIImageOrientation)camp_imageOrientationFromCGImagePropertyOrientation:(CGImagePropertyOrientation)cgOrientation {
    
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (cgOrientation) {
        case kCGImagePropertyOrientationUp:             orientation = UIImageOrientationUp; break;
        case kCGImagePropertyOrientationDown:           orientation = UIImageOrientationDown; break;
        case kCGImagePropertyOrientationLeft:           orientation = UIImageOrientationLeft; break;
        case kCGImagePropertyOrientationRight:          orientation = UIImageOrientationRight; break;
        case kCGImagePropertyOrientationUpMirrored:     orientation = UIImageOrientationUpMirrored; break;
        case kCGImagePropertyOrientationDownMirrored:   orientation = UIImageOrientationDownMirrored; break;
        case kCGImagePropertyOrientationLeftMirrored:   orientation = UIImageOrientationLeftMirrored; break;
        case kCGImagePropertyOrientationRightMirrored:  orientation = UIImageOrientationRightMirrored; break;
    }
    return orientation;
}

+ (CGImagePropertyOrientation)camp_cgImagePropertyOrientationFromUIImageOrientation:(UIImageOrientation)imageOrientation {
    
    switch (imageOrientation) {
        case UIImageOrientationUp: return kCGImagePropertyOrientationUp;
        case UIImageOrientationDown: return kCGImagePropertyOrientationDown;
        case UIImageOrientationLeft: return kCGImagePropertyOrientationLeft;
        case UIImageOrientationRight: return kCGImagePropertyOrientationRight;
        case UIImageOrientationUpMirrored: return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDownMirrored: return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored: return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRightMirrored: return kCGImagePropertyOrientationRightMirrored;
        default:
            return kCGImagePropertyOrientationUp;
    }
}

@end

