//
//  UIImage+CameraPicker.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerOverlayView.h"

@import UIKit;

typedef void (^DrawBlock)(CGContextRef context, CGSize size);

typedef NS_ENUM(NSInteger, CameraPickerPhotoSize);

@interface UIImage (CameraPicker)

+ (UIImage *)camp_imageWithSize:(CGSize)size drawBlock:(DrawBlock)drawBlock;

+ (UIImage *)camp_imageWithCameraPickerPhotoSize:(CameraPickerPhotoSize)photoSize forImageData:(NSData *)imageData;
- (UIImage *)camp_scaleImage:(CGFloat)scale;
- (UIImage *)camp_rotatedImageAccordingToImageOrientation;

- (BOOL)camp_writeJPEGToMemory:(NSMutableData **)memory withQuality:(double)quality;

#pragma mark - Zero-Copy Resize

+ (UIImage *)camp_resizedImageFromImageWithData:(NSData *)imageData subsampleFactor:(NSUInteger)subsampleFactor;

#pragma mark - Utils

+ (UIImageOrientation)camp_imageOrientationFromCGImagePropertyOrientation:(CGImagePropertyOrientation)cgOrientation;
+ (CGImagePropertyOrientation)camp_cgImagePropertyOrientationFromUIImageOrientation:(UIImageOrientation)imageOrientation;

@end
