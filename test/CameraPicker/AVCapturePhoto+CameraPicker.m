//
//  AVCapturePhoto+CameraPicker.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "AVCapturePhoto+CameraPicker.h"
#import "CameraPickerUIUtils.h"

#import "UIImage+CameraPicker.h"

@implementation AVCapturePhoto (CameraPicker)

- (UIImage *)Camp_previewUIImage {
    
    /* A subsampling factor of 2 is safe (image will not appear pixelated) given the high resolution of the output */
    UIImage *previewImage = [UIImage camp_resizedImageFromImageWithData:self.fileDataRepresentation subsampleFactor:2];
    if (!previewImage) {
        
        CGImageRef cgImage = self.CGImageRepresentation;
        if (cgImage) {
            CGImagePropertyOrientation imageOrientation;
            if (self.metadata[(__bridge NSString *)kCGImagePropertyOrientation]) {
                imageOrientation = (CGImagePropertyOrientation)((NSNumber *)self.metadata[(__bridge NSString *)kCGImagePropertyOrientation]).integerValue;
            } else {
                imageOrientation = CameraPickerUIUtils.sharedInstance.currentImageOrientation;
            }
            previewImage = [UIImage imageWithCGImage:cgImage scale:previewImage.scale orientation:[UIImage camp_imageOrientationFromCGImagePropertyOrientation:imageOrientation]];
        }
    }
    return previewImage;
}

@end
