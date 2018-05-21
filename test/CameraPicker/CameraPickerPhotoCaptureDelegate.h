//
//  CameraPickerPhotoCaptureDelegate.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import AVFoundation;

API_AVAILABLE(ios(10.0))
@interface CameraPickerPhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings
                willCapturePhotoAnimationBlock:(void (^)(void))willCapturePhotoAnimationBlock
                             completionHandler:(void (^)(CameraPickerPhotoCaptureDelegate *, NSError *, NSData *, UIImage *))completionHandler;

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;

@end
