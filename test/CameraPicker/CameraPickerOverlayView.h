//
//  CameraPickerOverlayView.h
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraPickerOverlayView;

typedef NS_ENUM(NSInteger, CameraDevicePosition) {
    CameraDevicePositionBack = 1,
    CameraDevicePositionFront,
    CameraDevicePositionUnspecified
};

typedef NS_ENUM(NSInteger, CameraPickerCaptureMode) {
    CameraPickerCaptureModePhoto = 0,
};

typedef NS_ENUM(NSInteger, CameraPickerPhotoSize) {
    CameraPickerPhotoSizeOriginal = 0,
    CameraPickerPhotoSizeMedium,
    CameraPickerPhotoSizeSmall
};

typedef NS_ENUM(NSInteger, CameraFlashMode);

@protocol CameraOverlayViewDelegate <NSObject>

// pre capture actions
- (void)cameraOverlayViewDidTapCancelButton:(CameraPickerOverlayView *)cameraOverlayView;
- (void)cameraOverlayViewDidTapSwitchCameraButton:(CameraPickerOverlayView *)cameraOverlayView;
- (void)cameraOverlayViewDidTapCaptureButton:(CameraPickerOverlayView *)cameraOverlayView;
- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView didChangeCaptureMode:(CameraPickerCaptureMode)captureMode;
- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView didChangeCameraFlashMode:(CameraFlashMode)flashMode;

// post capture actions
- (void)cameraOverlayViewDidTapDoneButton:(CameraPickerOverlayView *)cameraOverlayView;
- (void)cameraOverlayViewDidTapRetakeButton:(CameraPickerOverlayView *)cameraOverlayView;
- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView didChangePhotoSize:(CameraPickerPhotoSize)photoSize;
- (void)cameraOverlayViewDidTapEditPhotoButton:(CameraPickerOverlayView *)cameraOverlayView;

@end

@interface CameraPickerOverlayView : UIView

@property (nonatomic, weak)                                         id<CameraOverlayViewDelegate> delegate;
@property (nonatomic, assign)                                       BOOL interactionWithUIEnabled;
@property (nonatomic, assign)                                       CameraDevicePosition cameraPosition;
@property (nonatomic, assign, getter=isSwitchCameraButtonAvailable) BOOL switchCameraButtonAvailable;
@property (nonatomic, assign, getter=isFlashAvailable)              BOOL flashAvailable;
@property (nonatomic, assign)                                       BOOL allowsPhotoEditing;
@property (nonatomic, assign)                                       CameraFlashMode flashMode;
@property (nonatomic, strong)                                       NSArray <NSNumber *> *availableFlashModes;
@property (nonatomic, assign)                                       CameraPickerCaptureMode captureMode;
@property (nonatomic, strong)                                       NSArray <NSNumber *>*availableCaptureModes;

- (void)prepareForPreCaptureState;
- (void)prepareForCapturedPhotoState:(UIImage *)previewImage;
- (void)updateCapturedPhoto:(UIImage *)capturedPhoto withSize:(CameraPickerPhotoSize)photoSize;
- (void)prepareForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
