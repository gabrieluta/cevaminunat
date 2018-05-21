//
//  CameraPickerAVFoundationModel.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerPreviewView.h"
#import "CameraPickerOverlayView.h"
#import "CameraPickerFlashHeaderView.h"

@import Foundation;
@import CoreMedia;

@class CameraPickerAVFoundationModel;

typedef NS_ENUM(NSInteger, CameraPickerVideoCodecType) {
    CameraPickerVideoCodecTypeHEVC, /* @"hvc1" */
    CameraPickerVideoCodecTypeH264, /* @"avc1" */
    CameraPickerVideoCodecTypeJPEG,  /* @"jpeg" */
    CameraPickerVideoCodecTypeAppleProRes4444, /* @"ap4h" */
    CameraPickerVideoCodecTypeAppleProres422, /* @"apcn" */
    CameraPickerVideoCodecTypeUnknown,
};

typedef NS_ENUM(NSInteger, CaptureSessionInterruptionReason) {
    CaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground               = 1,
    CaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient                   = 2,
    CaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient                   = 3,
    CaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps = 4,
    CaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure        = 5,
    CaptureSessionInterruptionReasonUnknown,
};

typedef NS_ENUM(NSInteger, CameraPickerSetupResult) {
    CameraPickerSetupResultSuccess,
    CameraPickerSetupResultCameraNotAuthorized,
    CameraPickerSetupResultSessionConfigurationFailed
};

@protocol CameraPickerAVFoundationModelDelegate <NSObject>

/**
 * @discussion
 *   It is guaranteed that these methods will be called on the main queue
 */
- (void)cameraDeviceDidBecomeAvailableForAVFoundationModel:(CameraPickerAVFoundationModel *)avFoundationModel;
- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeCaptureSessionRunningStatus:(BOOL)isRunning;
- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didInterruptSessionWithReason:(CaptureSessionInterruptionReason)interruptionReason;
- (void)avFoundationModelDidEndSessionInterruption:(CameraPickerAVFoundationModel *)model;
- (void)avFoundationModelDidChangeVideoSubjectArea:(CameraPickerAVFoundationModel *)model;
- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeFocusPointOfInterest:(CGPoint)focusPointOfInterest;
- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeAdjustingFocus:(BOOL)isAdjustingFocus;

@end

@interface CameraPickerAVFoundationModel : NSObject

/* Designated Initializer */
- (instancetype)initWithPreviewView:(CameraPickerPreviewView *)previewView NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, weak) id<CameraPickerAVFoundationModelDelegate> delegate;

@property (nonatomic, assign) CameraPickerSetupResult setupResult;
@property (nonatomic) void (^startedRecordingVideoBlock)(void);

/*
 * @discussion
 * error might be set even when success == YES
 * Example: User starts filming and the user puts the app in the background.
 * Video recording finishes unexpectedly (hence error is set), but videoURL contains
 * what was filmed before putting the app in background (success is YES).
 */
@property (nonatomic) void (^finishedRecordingVideoBlock)(BOOL success, NSError *error, NSURL *videoURL);

- (void)requireCameraAuthorizationAndConfigureSession;
- (void)configureSession;
- (void)startRunning;
- (void)stopRunning;

/**
 @discussion
 The completion block will be executed on the main queue
 */
- (void)capturePhotoWithAnimations:(void (^)(void))captureAnimations
                        completion:(void (^)(NSError * error, NSData *imageData, UIImage *previewImage))completionBlock;

/** Movie recording */
- (void)toggleMovieRecoring;

/**
 * @discussion
 * Use this method to destroy a video file created with this class.
 */
+ (BOOL)destroyFileWithURL:(NSURL *)fielURL;

- (CameraDevicePosition)currentCameraPosition;

/**
 * @discussion
 *   Returns an array of CameraFlashMode
 */
- (NSArray <NSNumber *>*)availableFlashModesForCurrentVideoDevice;
- (BOOL)currentCameraDeviceHasFlash;
- (void)changeFlashMode:(CameraFlashMode)flashMode
             completion:(void (^)(CameraFlashMode flashMode))completion;

- (void)changeCaptureMode:(CameraPickerCaptureMode)captureMode
               completion:(void (^)(BOOL success))completion;

- (void)toggleCameraWithCompletion:(void (^)(void))completion;

/* Focus */

- (BOOL)isFocusPointOfInterestSupported;

/**
 * @param devicePoint in device coordinates.
 * @discussion
 * see - [AVCaptureVideoPreviewLayer captureDevicePointOfInterestForPoint:pointInView]
 * to convert it to device coordinates.
 */
- (void)focusAndExposePointOfInterest:(CGPoint)devicePoint;

/**
 * @discussion
 * Call this method only if isFocusPointOfInterestSupported returns YES.
 * Otherwise CGPointZero will be returned.
 * The returned point is in the coordinates of previewView.videoPreviewLayer.
 */
- (CGPoint)focusPointOfInterest;

/* ISO */
- (float)currentISO;
- (float)minISO;
- (float)maxISO;
- (void)setISO:(float)ISO;

/* Exposure Duration*/
- (CMTime)currentExposureDuration;
- (CMTime)minExposureDuration;
- (CMTime)maxExposureDuration;
- (void)setExposureDuration:(CMTime)exposureDuration;

/**
 @discussion This method must be called on the main queue
 because it may modify a layer of previewView
 */
- (void)changeVideoOrientationIfNeeded;

- (void)tryToResuemCaptureSessionWithCompletion:(void(^)(BOOL sessionIsRunning))completionHandler;

+ (NSInteger)uniqueDevicePositionsCount;
+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time;


/* Codec Management */
@property (nonatomic) CameraPickerVideoCodecType preferredPhotoCaptureCodec;
@property (nonatomic) CameraPickerVideoCodecType preferredMovieCaptureCodec;
+ (CameraPickerVideoCodecType)defaultPhotoCaptureCodec;
+ (CameraPickerVideoCodecType)defaultMovieCaptureCodec;
/* @return an array of CameraPickerVideoCodecType wrapped as NSNumbers */
+ (NSArray <NSNumber *> *)availablePhotoCaptureCodecs;
+ (NSArray <NSNumber *> *)availableMovieCaptureCodecs;

@end
