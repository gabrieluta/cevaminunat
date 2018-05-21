//
//  CameraPickerPhotoCaptureDelegate.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerPhotoCaptureDelegate.h"

#import "AVCapturePhoto+CameraPicker.h"
#import "UIImage+CameraPicker.h"

@interface CameraPickerPhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic) void (^willCapturePhotoAnimationBlock)(void);
@property (nonatomic) void (^completionHandler)(CameraPickerPhotoCaptureDelegate *photoCaptureDelegate, NSError *error, NSData *imageData, UIImage *imageThumbnail);

@end

@implementation CameraPickerPhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings
                willCapturePhotoAnimationBlock:(void (^)(void))willCapturePhotoAnimationBlock
                             completionHandler:(void (^)(CameraPickerPhotoCaptureDelegate *, NSError *, NSData *, UIImage *))completionHandler {
    self = [super init];
    if (self) {
        self.requestedPhotoSettings = requestedPhotoSettings;
        self.willCapturePhotoAnimationBlock = willCapturePhotoAnimationBlock;
        self.completionHandler = completionHandler;
    }
    return self;
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput
didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error capturing image %@", error.localizedDescription);
        self.completionHandler(self, error, nil, nil);
        return;
    }
    
    UIImage *previewImage;
    NSData *imageData;
    if (photoSampleBuffer) {
        
        imageData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                                previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        
        previewImage = [UIImage imageWithData:imageData];
    }
    
    if (!previewImage && imageData) {
        previewImage = [UIImage imageWithData:imageData];
    }
    
    if (!imageData || !previewImage) {
        imageData = nil;
        previewImage = nil;
    }
    
    self.completionHandler(self, error, imageData, previewImage);
}

#ifdef __IPHONE_11_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhoto:(AVCapturePhoto *)photo
                error:(nullable NSError *)error {
    
    if (error) {
        NSLog(@"Error capturing image %@", error.localizedDescription);
        self.completionHandler(self, error, nil, nil);
        return;
    }
    
    NSData *imageData = photo.fileDataRepresentation;
    UIImage *previewImage = [photo camp_previewUIImage];
    
    if (!imageData && previewImage) {
        NSMutableData *imageContent = [[NSMutableData alloc] init];
        if ([previewImage camp_writeJPEGToMemory:&imageContent withQuality:1.0f]) {
            imageData = imageContent;
        }
    }
    
    if (!previewImage && imageData) {
        previewImage = [UIImage imageWithData:imageData];
    }
    
    if (!imageData || !previewImage) {
        imageData = nil;
        previewImage = nil;
    }
    
    self.completionHandler(self, error, imageData, previewImage);
}

#pragma clang diagnostic pop
#endif

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    
    // Perform animations block on the main queue
    
    if (self.willCapturePhotoAnimationBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.willCapturePhotoAnimationBlock();
        });
    }
}

@end

