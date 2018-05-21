//
//  CameraPickerPreviewView.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import UIKit;

@class AVCaptureSession;
@class AVCaptureVideoPreviewLayer;

@interface CameraPickerPreviewView : UIView

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureSession *session;

@property (nonatomic, weak, readonly) UIButton *resumeButton;
- (void)setShowResumeButton:(BOOL)show animated:(BOOL)animated;

@property (nonatomic, weak, readonly) UILabel *cameraUnavailableLabel;
- (void)setShowCameraUnavailableLabel:(BOOL)show animated:(BOOL)animated;

@end

