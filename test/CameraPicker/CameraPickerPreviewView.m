//
//  CameraPickerPreviewView.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerPreviewView.h"
#import "CameraPickerAppearance.h"
#import "CameraPickerResourceLoader.h"

@import AVFoundation;

@interface CameraPickerPreviewView()

@property (nonatomic, weak, readwrite) UIButton *resumeButton;
@property (nonatomic, weak, readwrite) UILabel *cameraUnavailableLabel;

@end

@implementation CameraPickerPreviewView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self setupUserInterface];
    }
    return self;
}

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session {
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    self.videoPreviewLayer.session = session;
}

- (void)setupUserInterface {
    
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self setupCameraUnavailableCameraLabel];
}

- (void)setupCameraUnavailableCameraLabel {
    
    UILabel *label = [[UILabel alloc] init];
    self.cameraUnavailableLabel = label;
    self.cameraUnavailableLabel.text = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerCameraUnavailableMessage"];
    self.cameraUnavailableLabel.textColor = CameraPickerAppearance.colorForUnavailableCameraLabelText;
    label.hidden = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:label];
    NSLayoutConstraint *labelCenterX = [label.centerXAnchor constraintEqualToAnchor:label.superview.centerXAnchor];
    NSLayoutConstraint *labelCenterY = [label.centerYAnchor constraintEqualToAnchor:label.superview.centerYAnchor];
    
    [NSLayoutConstraint activateConstraints:@[labelCenterX, labelCenterY]];
}



#pragma mark - Public API

- (void)setShowResumeButton:(BOOL)show
                   animated:(BOOL)animated {
    
    UIButton *resumeButton = self.resumeButton;
    if (resumeButton.hidden == !show) {
        return;
    }
    
    if (animated) {
        if (show) {
            
            resumeButton.alpha = 0.0;
            resumeButton.hidden = NO;
            [UIView animateWithDuration:[CameraPickerAppearance defaultPresentationDuration]
                             animations:^{
                                 resumeButton.alpha = 1.0f;
                             }];
        } else {
            
            [UIView animateWithDuration:[CameraPickerAppearance defaultDismissalDuration]
                             animations:^{
                                 resumeButton.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 resumeButton.hidden = YES;
                             }];
        }
    } else {
        resumeButton.alpha = show ? 1.0f : 0.0f;
        resumeButton.hidden = !show;
    }
}

- (void)setShowCameraUnavailableLabel:(BOOL)show
                             animated:(BOOL)animated {
    
    UILabel *cameraUnavailableLabel = self.cameraUnavailableLabel;
    if (cameraUnavailableLabel.hidden == !show) {
        return;
    }
    
    if (animated) {
        
        if (show) {
            
            cameraUnavailableLabel.alpha = 0.0f;
            cameraUnavailableLabel.hidden = NO;
            [UIView animateWithDuration:[CameraPickerAppearance defaultPresentationDuration]
                             animations:^{
                                 cameraUnavailableLabel.alpha = 1.0f;
                             }];
        } else {
            
            [UIView animateWithDuration:[CameraPickerAppearance defaultDismissalDuration]
                             animations:^{
                                 cameraUnavailableLabel.alpha = 0.0;
                             } completion:^(BOOL finished) {
                                 cameraUnavailableLabel.hidden = YES;
                             }];
        }
    } else {
        cameraUnavailableLabel.alpha = show? 1.0f : 0.0f;
        cameraUnavailableLabel.hidden = !show;
    }
}

@end
