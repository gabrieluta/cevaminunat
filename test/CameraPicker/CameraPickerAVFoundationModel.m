//
//  CameraPickerAVFoundationModel.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerAVFoundationModel.h"

#import "CameraPickerUIUtils.h"

#import "UIImage+CameraPicker.h"

#ifdef __IPHONE_11_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
#import "CameraPickerPhotoCaptureDelegate.h"
#endif

@import AVFoundation;
@import Photos;

static void * SessionRunningContext = &SessionRunningContext;

@interface CameraPickerAVFoundationModel ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureOutput *captureOutput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureDeviceInput *audioInput;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureFocusMode focusMode;
@property (nonatomic) AVCaptureExposureMode exposureMode;

#ifdef __IPHONE_11_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
@property (nonatomic, strong) CameraPickerPhotoCaptureDelegate *photoCaptureDelegate;
#endif

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation CameraPickerAVFoundationModel


- (instancetype)initWithPreviewView:(CameraPickerPreviewView *)previewView {
    
    self = [super init];
    if (self) {
        
        /* Create the AVCaptureSession */
        _session = [[AVCaptureSession alloc] init];
        
        /* Communicate with the session and other session objects on this queue. */
        _sessionQueue = dispatch_queue_create("com.4psa.camerapicker.sessionqueue", DISPATCH_QUEUE_SERIAL) ;
        
        previewView.session = _session;
        
        _videoPreviewLayer = previewView.videoPreviewLayer;
        _focusMode = CameraPickerAVFoundationModel.defaultFocusMode;
        _exposureMode = CameraPickerAVFoundationModel.defaultExposureMode;
        
        _setupResult = CameraPickerSetupResultSuccess;
        
        _preferredPhotoCaptureCodec = CameraPickerAVFoundationModel.defaultPhotoCaptureCodec;
        _preferredMovieCaptureCodec = CameraPickerAVFoundationModel.defaultMovieCaptureCodec;
        
        [self addCaptureSessionObservers];
    }
    return self;
}

- (void)dealloc {
    [self removeObservers];
}

+ (NSInteger)uniqueDevicePositionsCount {
    
    NSMutableArray<NSNumber *> *uniqueDevicePositions = [NSMutableArray array];
    
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDeviceDiscoverySession
                                               discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera,
                                                                                 AVCaptureDeviceTypeBuiltInTelephotoCamera,
                                                                                 AVCaptureDeviceTypeBuiltInDualCamera]
                                               mediaType:AVMediaTypeVideo
                                               position:AVCaptureDevicePositionUnspecified].devices;
        for (AVCaptureDevice *device in devices) {
            if (![uniqueDevicePositions containsObject:@(device.position)]) {
                [uniqueDevicePositions addObject:@(device.position)];
            }
        }
    } else {
        
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (![uniqueDevicePositions containsObject:@(device.position)]) {
                [uniqueDevicePositions addObject:@(device.position)];
            }
        }
    }
    
    return uniqueDevicePositions.count;
}

+ (BOOL)device:(AVCaptureDevice *)device supportsFlashMode:(AVCaptureFlashMode)flashMode {
    
    if ([device hasFlash]) {
        if ([device isFlashModeSupported:flashMode]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)device:(AVCaptureDevice *)device supportsCameraFlashMode:(CameraFlashMode)flashMode {
    return [CameraPickerAVFoundationModel device:device
                                  supportsFlashMode:[CameraPickerAVFoundationModel flashModeForCameraFlashMode:flashMode]];
}


+ (NSArray <NSNumber *>*)availableFlashModesForDevice:(AVCaptureDevice *)device {
    
    NSMutableArray *availableFlashModes = [NSMutableArray arrayWithCapacity:3];
    if ([device hasFlash]) {
        if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [availableFlashModes addObject:@(CameraFlashModeAuto)];
        }
        if ([device isFlashModeSupported:AVCaptureFlashModeOn]) {
            [availableFlashModes addObject:@(CameraFlashModeOn)];
        }
        if ([device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [availableFlashModes addObject:@(CameraFlashModeOff)];
        }
        return availableFlashModes;
    }
    return nil;
}

#pragma mark - Capture Session Initiation

- (void)startRunning {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        [weakSelf.session startRunning];
        weakSelf.sessionRunning = weakSelf.session.isRunning;
    }];
}

- (void)stopRunning {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        [weakSelf.session stopRunning];
        weakSelf.sessionRunning = weakSelf.session.isRunning;
    }];
}

#pragma mark - Capture Session Management

- (void)requireCameraAuthorizationAndConfigureSession {
    
    [self configureSession];
    
    /*
     Check video authorization status. Video access is required and audio
     access is optional. If audio access is denied, audio is not recorded
     during movie recording.
     */
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
            
        case AVAuthorizationStatusAuthorized: {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult = CameraPickerSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default: {
            
            // The user has previously denied access.
            self.setupResult = CameraPickerSetupResultCameraNotAuthorized;
            break;
        }
    }
}

- (void)configureSession {
    
    __weak __typeof(self) weakSelf = self;
    
    /*
     Setup the capture session.
     In general it is not safe to mutate an AVCaptureSession or any of its
     inputs, outputs, or connections from multiple threads at the same time.
     
     Why not do all of this on the main queue?
     Because -[AVCaptureSession startRunning] is a blocking call which can
     take a long time. We dispatch session setup to the sessionQueue so
     that the main queue isn't blocked, which keeps the UI responsive.
     */
    [self dispatchOnSessionQueue:^{
        
        if (weakSelf.setupResult != CameraPickerSetupResultSuccess) {
            return;
        }
        
        [weakSelf.session beginConfiguration];
        
        /*
         * We do not create an AVCaptureMovieFileOutput when setting up the session because the
         * AVCaptureMovieFileOutput does not support movie recording with AVCaptureSessionPresetPhoto.
         */
        if ([weakSelf.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            weakSelf.session.sessionPreset = AVCaptureSessionPresetPhoto;
        } else {
            NSLog(@"Cannot set captureSession preset to AVCaptureSessionPresetPhoto");
        }
        
        AVCaptureDeviceInput *videoDeviceInput = [CameraPickerAVFoundationModel backFacingCameraDeviceInput];
        if (!videoDeviceInput) {
            
            /* In some cases where users break their phones, no back camera is available.
             * In this case, we should default to the front wide angle camera
             */
            videoDeviceInput = [CameraPickerAVFoundationModel frontFacingCameraDeviceInput];
            if (!videoDeviceInput) {
                
                /* No camera available, there is nothing we can do */
                NSLog(@"Could not get video device input (no camera available)");
                weakSelf.setupResult = CameraPickerSetupResultSessionConfigurationFailed;
                [weakSelf.session commitConfiguration];
                return;
            }
        }
        
        /* Add video input */
        if ([weakSelf.session canAddInput:videoDeviceInput]) {
            [weakSelf.session addInput:videoDeviceInput];
            weakSelf.videoDeviceInput = videoDeviceInput;
            
        } else {
            NSLog(@"Could not add video device input to the session");
            weakSelf.setupResult = CameraPickerSetupResultSessionConfigurationFailed;
            [weakSelf.session commitConfiguration];
            return;
        }
        
        [weakSelf addObserverForCurrentVideoDevice];
        
        /* Add capture output */
        AVCaptureOutput *captureOutput = [CameraPickerAVFoundationModel createPhotoCaptureOutput];
        if ([weakSelf.session canAddOutput:captureOutput]) {
            [weakSelf.session addOutput:captureOutput];
            weakSelf.captureOutput = captureOutput;
            
        } else {
            NSLog( @"Could not add photo output to the session" );
            weakSelf.setupResult = CameraPickerSetupResultSessionConfigurationFailed;
            [weakSelf.session commitConfiguration];
            return;
        }
        
        weakSelf.backgroundRecordingID = UIBackgroundTaskInvalid;
        
        [weakSelf.session commitConfiguration];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate cameraDeviceDidBecomeAvailableForAVFoundationModel:weakSelf];
        });
    }];
}

#pragma mark - Flash

- (BOOL)currentCameraDeviceHasFlash {
    BOOL hasFlash = [self.videoDeviceInput.device hasFlash];
    return hasFlash;
}

- (NSArray <NSNumber *>*)availableFlashModesForCurrentVideoDevice {
    return [CameraPickerAVFoundationModel availableFlashModesForDevice:self.videoDeviceInput.device];
}

/**
 * @discussion
 * The completion block will be executed on the main queue
 */
- (void)changeFlashMode:(CameraFlashMode)flashMode
             completion:(void (^)(CameraFlashMode flashMode))completion {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        
        AVCaptureFlashMode avCaptureFlashMode = [CameraPickerAVFoundationModel flashModeForCameraFlashMode:flashMode];
        if ([CameraPickerAVFoundationModel device:weakSelf.videoDeviceInput.device supportsFlashMode:avCaptureFlashMode]) {
            NSError *error;
            if ([weakSelf.videoDeviceInput.device lockForConfiguration:&error]) {
                weakSelf.videoDeviceInput.device.flashMode = avCaptureFlashMode;
                [weakSelf.videoDeviceInput.device unlockForConfiguration];
            } else {
                NSLog(@"Error locking device to change flash %@", error);
            }
        }
        
        CameraFlashMode currentFlashMode = [CameraPickerAVFoundationModel flashModeForAVCaptureFlashMode:weakSelf.videoDeviceInput.device.flashMode];
        
        // Execute the completion block on the main queue
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(currentFlashMode);
            });
        }
    }];
}


#pragma mark - Capture Mode

/**
 * @discussion
 * The completion block will be executed on the main queue
 */
- (void)changeCaptureMode:(CameraPickerCaptureMode)captureMode
               completion:(void (^)(BOOL success))completion {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        
        BOOL success = YES;
        
        [weakSelf.session beginConfiguration];
        
        switch (captureMode) {
                
            case CameraPickerCaptureModePhoto: {
                /*
                 Remove the AVCaptureMovieFileOutput from the session because movie recording is
                 not supported with AVCaptureSessionPresetPhoto.
                 Also remove AVCaptureDeviceInput since it is not needed
                 */
                [weakSelf.session removeOutput:weakSelf.movieFileOutput];
                [weakSelf.session removeInput:weakSelf.audioInput];
                if ([weakSelf.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
                    weakSelf.session.sessionPreset = AVCaptureSessionPresetPhoto;
                } else {
                    NSLog(@"Cannot set captureSession preset to AVCaptureSessionPresetPhoto");
                }
                weakSelf.movieFileOutput = nil;
            } break;
        }
        
        /* While filming enable smooth autofocus if possible so that focus changes are less rough. */
        AVCaptureDevice *captureDevice = weakSelf.videoDeviceInput.device;
        NSError *error = nil;
        if ([captureDevice lockForConfiguration:&error]) {
            if (captureDevice.isSmoothAutoFocusSupported) {
                captureDevice.smoothAutoFocusEnabled = NO;
            }
            [captureDevice unlockForConfiguration];
        }
        
        [weakSelf.session commitConfiguration];
        
        /* Execute the completion block on the main queue */
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success);
            });
        }
    }];
}

#pragma mark - Focus

- (BOOL)isFocusPointOfInterestSupported {
    return [self.videoDeviceInput.device isFocusPointOfInterestSupported];
}

- (CGPoint)focusPointOfInterest {
    
    if (self.videoPreviewLayer && [self.videoDeviceInput.device isFocusPointOfInterestSupported]) {
        return [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:[self.videoDeviceInput.device focusPointOfInterest]];
    } else {
        return CGPointZero;
    }
}

- (void)focusAndExposePointOfInterest:(CGPoint)devicePoint {
    
    [self focusWithMode:self.focusMode
         exposeWithMode:self.exposureMode
          atDevicePoint:devicePoint
monitorSubjectAreaChange:YES];
    
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
       exposeWithMode:(AVCaptureExposureMode)exposureMode
        atDevicePoint:(CGPoint)point
monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchSynchronouslyOnSessionQueue:^{
        
        AVCaptureDevice *device = weakSelf.videoDeviceInput.device;
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            /*
             * Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
             * Call set(Focus/Exposure)Mode() to apply the new point of interest.
             */
            if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
                
                NSLog(@"Setting focus point");
                
                /* Remove KVO observer so that callback is not called when we set the value */
                [self removeFocusPointOfInterestObserver];
                device.focusPointOfInterest = point;
                [self addFocusPointOfInterestObserver];
                device.focusMode = focusMode;
            }
            
            if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
                
                /* Remove KVO observer so that callback is not called when we set the value */
                [self removeExposurePointOfInterestObserver];
                device.exposurePointOfInterest = point;
                [self addExposurePointOfInterestObserver];
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Could not lock device for configuration: %@", error );
        }
    }];
}

#pragma mark - ISO

- (float)currentISO {
    return self.videoDeviceInput.device.ISO;
}

- (float)minISO {
    return self.videoDeviceInput.device.activeFormat.minISO;
}

- (float)maxISO {
    return self.videoDeviceInput.device.activeFormat.maxISO;
}

- (void)setISO:(float)ISO {
    [self setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:nil];
}

#pragma mark - Exposure Duration

- (CMTime)currentExposureDuration {
    return self.videoDeviceInput.device.exposureDuration;
}

- (CMTime)minExposureDuration {
    CMTime time = self.videoDeviceInput.device.activeFormat.minExposureDuration;
    NSLog(@"%lld %d", time.value, time.timescale);
    return time;
}

- (CMTime)maxExposureDuration {
    return self.videoDeviceInput.device.activeFormat.maxExposureDuration;
}

- (void)setExposureDuration:(CMTime)exposureDuration {
    [self setExposureModeCustomWithDuration:exposureDuration ISO:AVCaptureISOCurrent completionHandler:nil];
}

- (void)setExposureModeCustomWithDuration:(CMTime)exposureDuration
                                      ISO:(float)ISO
                        completionHandler:(void (^)(CMTime syncTime))completionHandler {
    
    __weak __typeof (self) weakSelf = self;
    [self dispatchSynchronouslyOnSessionQueue:^{
        
        NSError *error = nil;
        if ([weakSelf.videoDeviceInput.device lockForConfiguration:&error]) {
            
            [weakSelf.videoDeviceInput.device setExposureModeCustomWithDuration:exposureDuration
                                                                            ISO:ISO
                                                              completionHandler:^(CMTime syncTime) {
                                                                  
                                                                  weakSelf.exposureMode = AVCaptureExposureModeCustom;
                                                                  if (completionHandler) {
                                                                      completionHandler(syncTime);
                                                                  }
                                                              }];
            [weakSelf.videoDeviceInput.device unlockForConfiguration];
        }
    }];
}

#pragma mark - Camera device

- (void)toggleCameraWithCompletion:(void (^)(void))completion {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        
        AVCaptureDevice *currentVideoDevice = weakSelf.videoDeviceInput.device;
        AVCaptureDeviceInput *newVideoDeviceInput = nil;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        if (currentPosition == AVCaptureDevicePositionBack) {
            newVideoDeviceInput = [CameraPickerAVFoundationModel frontFacingCameraDeviceInput];
        } else {
            newVideoDeviceInput = [CameraPickerAVFoundationModel backFacingCameraDeviceInput];
        }
        
        if (newVideoDeviceInput) {
            
            [weakSelf.session beginConfiguration];
            
            /* Remove the existing device input first, since using the front and back camera simultaneously is not supported. */
            [weakSelf.session removeInput:weakSelf.videoDeviceInput];
            
            [weakSelf removeObserversForCurrentVideoDevice];
            
            if ([weakSelf.session canAddInput:newVideoDeviceInput]) {
                [weakSelf.session addInput:newVideoDeviceInput];
                weakSelf.videoDeviceInput = newVideoDeviceInput;
            } else {
                /* keep the old camera */
                [weakSelf.session addInput:weakSelf.videoDeviceInput];
            }
            
            [weakSelf addObserverForCurrentVideoDevice];
            
            AVCaptureConnection *movieFileOutputConnection = [weakSelf.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (movieFileOutputConnection.isVideoStabilizationSupported) {
                movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            [weakSelf.session commitConfiguration];
        }
        
        /* Execute the completion block on the main queue */
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }];
}

- (CameraDevicePosition)currentCameraPosition {
    return [CameraPickerAVFoundationModel cameraDevicePositionForAVCaptureDevicePosition:self.videoDeviceInput.device.position];
}

#pragma mark - Codec Management

+ (NSArray <NSNumber *> *)availablePhotoCaptureCodecs {
    
    NSMutableArray *availablePhotoCaptureCodecs = [[NSMutableArray alloc] init];
    NSArray <AVVideoCodecType> *availableVideoCodecTypes = nil;
    AVCaptureOutput *photoOutput = [CameraPickerAVFoundationModel createPhotoCaptureOutput];
    
    if (NSClassFromString(@"AVCapturePhotoOutput") && [photoOutput isKindOfClass:AVCapturePhotoOutput.class]) {
        availableVideoCodecTypes = [((AVCapturePhotoOutput *)photoOutput) availablePhotoCodecTypes];
    } else if ([photoOutput isKindOfClass:AVCaptureStillImageOutput.class]) {
        availableVideoCodecTypes = [((AVCaptureStillImageOutput *)photoOutput) availableImageDataCodecTypes];
    }
    
    for (AVVideoCodecType videoCodecType in availableVideoCodecTypes) {
        CameraPickerVideoCodecType codecType = [CameraPickerAVFoundationModel cameraPickerVideoCodecTypeForAVVideoCodecType:videoCodecType];
        if (codecType != CameraPickerVideoCodecTypeUnknown) {
            [availablePhotoCaptureCodecs addObject:@(codecType)];
        }
    }
    
    return availablePhotoCaptureCodecs;
}

+ (NSArray <NSNumber *> *)availableMovieCaptureCodecs {
    
    NSMutableArray *availableMovieCaptureCodecs = [[NSMutableArray alloc] initWithCapacity:4];
    AVCaptureMovieFileOutput *movieOutput = [CameraPickerAVFoundationModel createMovieFileOutput];
    for (AVVideoCodecType videoCodecType in [movieOutput availableVideoCodecTypes]) {
        CameraPickerVideoCodecType codecType = [CameraPickerAVFoundationModel cameraPickerVideoCodecTypeForAVVideoCodecType:videoCodecType];
        if (codecType != CameraPickerVideoCodecTypeUnknown) {
            [availableMovieCaptureCodecs addObject:@(codecType)];
        }
    }
    
    return availableMovieCaptureCodecs;
}

+ (CameraPickerVideoCodecType)defaultPhotoCaptureCodec {
    return CameraPickerVideoCodecTypeJPEG;
}

+ (CameraPickerVideoCodecType)defaultMovieCaptureCodec {
    return CameraPickerVideoCodecTypeH264;
}

#pragma mark - Capture Photos

/**
 * @discussion
 * The completion block will be executed on the main queue
 */
- (void)capturePhotoWithAnimations:(void (^)(void))captureAnimations
                        completion:(void (^)(NSError * error, NSData *imageData, UIImage *previewImage))completionBlock {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        
        /* Set the video orientation so that it is included in the metadata */
        AVCaptureConnection *captureConnection = [weakSelf.captureOutput connectionWithMediaType:AVMediaTypeVideo];
        captureConnection.videoOrientation = CameraPickerUIUtils.sharedInstance.currentVideoOrientation;
        
        AVCaptureFlashMode flashMode = weakSelf.videoDeviceInput.device.flashMode;
        
        if (NSClassFromString(@"AVCapturePhotoOutput") && [weakSelf.captureOutput isKindOfClass:AVCapturePhotoOutput.class]) {
            [weakSelf capturePhotoWithPhotoOutput:(AVCapturePhotoOutput *)weakSelf.captureOutput
                                        flashMode:flashMode
                                       animations:captureAnimations
                                       completion:completionBlock];
        } else if ([weakSelf.captureOutput isKindOfClass:AVCaptureStillImageOutput.class]) {
            
            [weakSelf capturePhotoWithStillImageOutput:(AVCaptureStillImageOutput *)weakSelf.captureOutput
                                             flashMode:flashMode
                                            animations:captureAnimations
                                            completion:completionBlock];
        } else {
            
            /* Execute the completion block on the main queue */
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, nil);
                });
            }
        }
    }];
}

/**
 * @discussion
 * The completion block will be executed on the main queue
 */
- (void)capturePhotoWithPhotoOutput:(AVCapturePhotoOutput *)photoOutput
                          flashMode:(AVCaptureFlashMode)flashMode
                         animations:(void (^)(void))captureAnimations
                         completion:(void (^)(NSError *error, NSData *imageData, UIImage *previewImage))completionBlock {
    
    
    AVVideoCodecType preferredAVVideoCodecType = [CameraPickerAVFoundationModel avVideoCodecTypeStringForCameraPickerVideoCodecType:self.preferredPhotoCaptureCodec];
    if (!preferredAVVideoCodecType) {
        preferredAVVideoCodecType = [CameraPickerAVFoundationModel avVideoCodecTypeStringForCameraPickerVideoCodecType:CameraPickerAVFoundationModel.defaultPhotoCaptureCodec];
    }
    
    /* AVCapturePhotoSettings objects cannot be reused (otherwise an exception is raised)
     * so we cannot keep this object in a property
     */
    AVCapturePhotoSettings *photoSettings;
    if (preferredAVVideoCodecType && [[photoOutput availablePhotoCodecTypes] containsObject:preferredAVVideoCodecType]) {
        
        photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{ AVVideoCodecKey : preferredAVVideoCodecType }];
    } else {
        photoSettings = [AVCapturePhotoSettings photoSettings];
    }
    
    photoSettings.flashMode = flashMode;
    CameraPickerPhotoCaptureDelegate *photoCaptureDelegate = [[CameraPickerPhotoCaptureDelegate alloc]
                                                                 initWithRequestedPhotoSettings:photoSettings
                                                                 willCapturePhotoAnimationBlock:captureAnimations
                                                                 completionHandler:^(CameraPickerPhotoCaptureDelegate *delegate, NSError *error, NSData *imageData, UIImage *image) {
                                                                     
                                                                     /* Execute the completion block on the main queue */
                                                                     if (completionBlock) {
                                                                         [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                                                                             completionBlock(error, imageData, image);
                                                                         }];
                                                                     }
                                                                 }];
    self.photoCaptureDelegate = photoCaptureDelegate;
    [photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
}

/**
 * @discussion
 * The completion block will be executed on the main queue
 */
- (void)capturePhotoWithStillImageOutput:(AVCaptureStillImageOutput *)stillImageOutput
                               flashMode:(AVCaptureFlashMode)flashMode
                              animations:(void (^)(void))captureAnimations
                              completion:(void (^)(NSError * error, NSData *imageData, UIImage *image))completionBlock {
    
    if (captureAnimations) {
        dispatch_async(dispatch_get_main_queue(), ^{
            captureAnimations();
        });
    }
    
    NSError *error;
    if ([self.videoDeviceInput.device lockForConfiguration:&error]) {
        self.videoDeviceInput.device.flashMode = flashMode;
        [self.videoDeviceInput.device unlockForConfiguration];
    } else {
        NSLog(@"Error setting flash for taking photo %@", error);
    }
    
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef photoSampleBuffer,
                                                                      NSError *error) {
                                                      
                                                      if (error) {
                                                          NSLog(@"Error capturing image %@", error.localizedDescription);
                                                      }
                                                      
                                                      UIImage *previewImage;
                                                      NSData *imageData;
                                                      if (photoSampleBuffer) {
                                                          
                                                          imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:photoSampleBuffer];
                                                          previewImage = [UIImage imageWithData:imageData];
                                                      }
                                                      
                                                      if (!previewImage && imageData) {
                                                          previewImage = [UIImage imageWithData:imageData];
                                                      }
                                                      
                                                      if (!previewImage || !imageData) {
                                                          previewImage = nil;
                                                          imageData = nil;
                                                      }
                                                      
                                                      // Execute the completion block on the main queue
                                                      if (completionBlock) {
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                              completionBlock(error, imageData, previewImage);
                                                          });
                                                      }
                                                  }];
}

#pragma mark - Record Movies

- (void)toggleMovieRecoring {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        
        if (!weakSelf.movieFileOutput.isRecording) {
            
            [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                
                if ([UIDevice currentDevice].isMultitaskingSupported ) {
                    /*
                     Setup background task.
                     This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                     callback is not received until AVCam returns to the foreground unless you request background execution time.
                     This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                     To conclude this background execution, -[endBackgroundTask:] is called in
                     -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                     */
                    weakSelf.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
                }
                
            }];
            
            /* Update the orientation on the movie file output video connection before starting recording. */
            AVCaptureConnection *movieFileOutputConnection = [weakSelf.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            movieFileOutputConnection.videoOrientation = CameraPickerUIUtils.sharedInstance.currentVideoOrientation;
            
            /* Set preferred video codec */
            CameraPickerVideoCodecType codecType = weakSelf.preferredMovieCaptureCodec;
            AVVideoCodecType preferredAVVideoCodecType = [CameraPickerAVFoundationModel avVideoCodecTypeStringForCameraPickerVideoCodecType:codecType];
            if (!preferredAVVideoCodecType) {
                codecType = CameraPickerAVFoundationModel.defaultMovieCaptureCodec;
                preferredAVVideoCodecType = [CameraPickerAVFoundationModel avVideoCodecTypeStringForCameraPickerVideoCodecType:codecType];
            }
            
            NSString *fileExtension = nil;
            if (preferredAVVideoCodecType && [weakSelf.movieFileOutput.availableVideoCodecTypes containsObject:preferredAVVideoCodecType]) {
                [weakSelf.movieFileOutput setOutputSettings:@{ AVVideoCodecKey : preferredAVVideoCodecType }
                                              forConnection:movieFileOutputConnection];
                fileExtension = [CameraPickerAVFoundationModel fileExtensionForCameraPickerCodecType:codecType];
            }
            
            if (!fileExtension) {
                fileExtension = @"mov";
                NSLog(@"Using default mov file extension for recording movie.");
            }
            
            /*  Start recording to a temporary file. */
            NSString *outputFileName = NSUUID.UUID.UUIDString;
            NSURL *outputURL = [[CameraPickerAVFoundationModel.temporaryDirectory URLByAppendingPathComponent:outputFileName] URLByAppendingPathExtension:fileExtension];
            [weakSelf.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:weakSelf];
        } else {
            [weakSelf.movieFileOutput stopRecording];
        }
    }];
}

+ (BOOL)destroyFileWithURL:(NSURL *)fileURL {
    
    NSError *error = nil;
    if ([NSFileManager.defaultManager fileExistsAtPath:fileURL.path]) {
        [NSFileManager.defaultManager removeItemAtPath:fileURL.path error:&error];
        if (!error) {
            
            NSLog(@"Destroyed file with URL %@", fileURL);
            return YES;
        } else {
            NSLog(@"Error destroying file with URL %@", fileURL);
        }
    } else {
        NSLog(@"Cannot destroy file with URL %@ because it does not exist.", fileURL);
    }
    
    return NO;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections {
    
    __weak __typeof(self) weakSelf = self;
    
    /* Setup Video Recording UI */
    if (self.startedRecordingVideoBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.startedRecordingVideoBlock();
        });
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    
    __weak __typeof(self) weakSelf = self;
    
    /*
     Note that currentBackgroundRecordingID is used to end the background task
     associated with this recording. This allows a new recording to be started,
     associated with a new UIBackgroundTaskIdentifier, once the movie file output's
     `recording` property is back to NO — which happens sometime after this method
     returns.
     
     Note: Since we use a unique file path for each recording, a new recording will
     not overwrite a recording currently being saved.
     */
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    BOOL success = YES;
    
    if (error) {
        NSLog(@"Movie file finishing error: %@", error);
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    
    if (!success) {
        [CameraPickerAVFoundationModel destroyFileWithURL:outputFileURL];
    }
    
    if (self.finishedRecordingVideoBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (currentBackgroundRecordingID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
            }
            
            weakSelf.finishedRecordingVideoBlock(success, error, outputFileURL);
        });
    }
}

#pragma mark - Resume capture session

- (void)tryToResuemCaptureSessionWithCompletion:(void(^)(BOOL sessionIsRunning))completionHandler {
    
    __weak __typeof(self) weakSelf = self;
    [self dispatchOnSessionQueue:^{
        /*
         The session might fail to start running, e.g., if a phone or FaceTime call is still
         using audio or video. A failure to start the session running will be communicated via
         a session runtime error notification. To avoid repeatedly failing to start the session
         running, we only try to restart the session running in the session runtime error handler
         if we aren't trying to resume the session running.
         */
        [weakSelf.session startRunning];
        weakSelf.sessionRunning = weakSelf.session.isRunning;
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(weakSelf.session.isRunning);
            });
        }
    }];
}

#pragma mark - Video Orientation Handling

- (void)changeVideoOrientationIfNeeded {
    
    /*
     Retrieve the video preview layer's video orientation on the main queue.
     We do this to ensure UI elements are accessed on
     the main thread and session configuration is done on the session queue.
     */
    AVCaptureConnection *connection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.videoPreviewLayer.connection.videoOrientation;
    connection.videoOrientation = videoPreviewLayerVideoOrientation;
}

#pragma mark KVO and Notifications

- (void)addCaptureSessionObservers {
    
    AVCaptureSession *captureSession = self.session;
    if (!captureSession) {
        return;
    }
    
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification
                                               object:self.session];
    
    /*
     A session can only run when the app is full screen. It will be interrupted
     in a multi-app layout, introduced in iOS 9, see also the documentation of
     AVCaptureSessionInterruptionReason. Add observers to handle these session
     interruptions and show a preview is paused message. See the documentation
     of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionWasInterrupted:)
                                                 name:AVCaptureSessionWasInterruptedNotification
                                               object:captureSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionInterruptionEnded:)
                                                 name:AVCaptureSessionInterruptionEndedNotification
                                               object:captureSession];
}

- (void)removeCaptureSessionObservers {
    
    AVCaptureSession *captureSession = self.session;
    if (!captureSession) {
        return;
    }
    
    [captureSession removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionRuntimeErrorNotification
                                                  object:captureSession];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionWasInterruptedNotification
                                                  object:captureSession];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionInterruptionEndedNotification
                                                  object:captureSession];
}

- (void)addObserverForCurrentVideoDevice {
    
    AVCaptureDevice *captureDevice = self.videoDeviceInput.device;
    if (!captureDevice) {
        return;
    }
    
    [self addFocusPointOfInterestObserver];
    [self addExposurePointOfInterestObserver];
    
    [captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(subjectAreaDidChange:)
                                                 name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                               object:captureDevice];
}

- (void)addFocusPointOfInterestObserver {
    
    if ([self.videoDeviceInput.device isFocusPointOfInterestSupported]) {
        [self.videoDeviceInput.device addObserver:self forKeyPath:@"focusPointOfInterest" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    }
}

- (void)removeFocusPointOfInterestObserver {
    
    if ([self.videoDeviceInput.device isFocusPointOfInterestSupported]) {
        [self.videoDeviceInput.device removeObserver:self forKeyPath:@"focusPointOfInterest"];
    }
}

- (void)addExposurePointOfInterestObserver {
    
    if ([self.videoDeviceInput.device isExposurePointOfInterestSupported]) {
        [self.videoDeviceInput.device addObserver:self forKeyPath:@"exposurePointOfInterest" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    }
}

- (void)removeExposurePointOfInterestObserver {
    
    if ([self.videoDeviceInput.device isExposurePointOfInterestSupported]) {
        [self.videoDeviceInput.device removeObserver:self forKeyPath:@"exposurePointOfInterest"];
    }
}

- (void)removeObserversForCurrentVideoDevice {
    
    AVCaptureDevice *captureDevice = self.videoDeviceInput.device;
    if (!captureDevice) {
        return;
    }
    
    [self removeFocusPointOfInterestObserver];
    [self removeExposurePointOfInterestObserver];
    
    [captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                  object:captureDevice];
}

- (void)removeObservers {
    [self removeCaptureSessionObservers];
    [self removeObserversForCurrentVideoDevice];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    __weak __typeof(self) weakSelf = self;
    
    if (context == SessionRunningContext) {
        
        if (object == self.videoDeviceInput.device) {
            
            if ([keyPath isEqualToString:@"focusPointOfInterest"]) {
                
                NSLog(@"Video device did change focus point of interest");
                CGPoint deviceNewPointOfInterest = [change[NSKeyValueChangeNewKey] CGPointValue];
                CGPoint viewNewPointOfInterest = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:deviceNewPointOfInterest];
                [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                    
                    if (weakSelf.videoPreviewLayer) {
                        [weakSelf.delegate avFoundationModel:weakSelf didChangeFocusPointOfInterest:viewNewPointOfInterest];
                    }
                }];
            } else if ([keyPath isEqualToString:@"exposurePointOfInterest"]) {
                
                NSLog(@"Video device did change exposure point of interest");
                CGPoint deviceNewPointOfInterest = [change[NSKeyValueChangeNewKey] CGPointValue];
                CGPoint viewNewPointOfInterest = [self.videoPreviewLayer pointForCaptureDevicePointOfInterest:deviceNewPointOfInterest];
                [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                    
                    if (weakSelf.videoPreviewLayer) {
                        [weakSelf.delegate avFoundationModel:weakSelf didChangeFocusPointOfInterest:viewNewPointOfInterest];
                    }
                }];
                
            } else if ([keyPath isEqualToString:@"adjustingFocus"]) {
                
                BOOL isAdjustingFocus = [change[NSKeyValueChangeNewKey] boolValue];
                if (isAdjustingFocus) {
                    NSLog(@"Video device is adjusting focus.");
                } else {
                    NSLog(@"Video device has stabilized focus.");
                }
                
                [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                    [weakSelf.delegate avFoundationModel:weakSelf didChangeAdjustingFocus:isAdjustingFocus];
                }];
            }
            
        } else if (object == self.session) {
            
            if ([keyPath isEqualToString:@"running"]) {
                
                BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
                NSLog(@"CaptureSession did change running %d", isSessionRunning);
                
                [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
                    [weakSelf.delegate avFoundationModel:weakSelf didChangeCaptureSessionRunningStatus:isSessionRunning];
                }];
            }
            
        } else {
            NSLog(@"Received unknown KVO noticication for object %@ keypath %@", object, keyPath);
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
    NSLog(@"Video subject area did change");
    
    __weak __typeof(self) weakSelf = self;
    [CameraPickerAVFoundationModel performBlockOnMainQueue:^{
        [weakSelf.delegate avFoundationModelDidChangeVideoSubjectArea:weakSelf];
    }];
}

- (void)sessionRuntimeError:(NSNotification *)notification {
    
    __weak __typeof(self) weakSelf = self;
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    
    /*
     Automatically try to restart the session running if media services were
     reset and the last start running succeeded. Otherwise, enable the user
     to try to resume the session running.
     */
    if (error.code == AVErrorMediaServicesWereReset) {
        [self dispatchOnSessionQueue:^{
            if (weakSelf.isSessionRunning) {
                [weakSelf.session startRunning];
                weakSelf.sessionRunning = weakSelf.session.isRunning;
            }
        }];
    }
    
    if (!weakSelf.sessionRunning) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate avFoundationModel:weakSelf didInterruptSessionWithReason:CaptureSessionInterruptionReasonUnknown];
        });
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification {
    
    AVCaptureSessionInterruptionReason avInterruptionReason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    CaptureSessionInterruptionReason interruptionReason;
    
    switch (avInterruptionReason) {
            
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
            interruptionReason = CaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground;
            NSLog(@"Capture session was interrupted with reason NotAvailableInBackground");
            break;
            
        case AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
            interruptionReason = CaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient;
            NSLog(@"Capture session was interrupted with reason AudioDeviceInUseByAnotherClient");
            break;
            
        case AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
            interruptionReason = CaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient;
            NSLog(@"Capture session was interrupted with reason VideoDeviceInUseByAnotherClient");
            break;
            
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
            interruptionReason = CaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps;
            NSLog(@"Capture session was interrupted with reason NotAvailableWithMultipleForegroundApps");
            break;
            
#ifdef __IPHONE_11_1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure:
            interruptionReason = CaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure;
            NSLog(@"Capture session was interrupted with reason VideoDeviceNotAvailableDueToSystemPressure");
            break;
#endif
            
        default:
            interruptionReason = CaptureSessionInterruptionReasonUnknown;
            break;
    }
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate avFoundationModel:weakSelf didInterruptSessionWithReason:interruptionReason];
    });
}

- (void)sessionInterruptionEnded:(NSNotification *)notification {
    
    NSLog(@"Capture session interruption ended");
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate avFoundationModelDidEndSessionInterruption:self];
    });
}

#pragma mark - Type conversions

+ (CameraFlashMode)flashModeForAVCaptureFlashMode:(AVCaptureFlashMode)flashMode {
    
    switch (flashMode) {
        case AVCaptureFlashModeAuto:
            return CameraFlashModeAuto;
        case AVCaptureFlashModeOn:
            return CameraFlashModeOn;
        case AVCaptureFlashModeOff:
            return CameraFlashModeOff;
    }
}

+ (AVCaptureFlashMode)flashModeForCameraFlashMode:(CameraFlashMode)flashMode {
    
    switch (flashMode) {
        case CameraFlashModeAuto:
            return AVCaptureFlashModeAuto;
        case CameraFlashModeOn:
            return AVCaptureFlashModeOn;
        case CameraFlashModeOff:
            return AVCaptureFlashModeOff;
    }
}

+ (CameraDevicePosition)cameraDevicePositionForAVCaptureDevicePosition:(AVCaptureDevicePosition)avCaptureDevicePosition {
    
    switch (avCaptureDevicePosition) {
            
        case AVCaptureDevicePositionBack:
            return CameraDevicePositionBack;
            
        case AVCaptureDevicePositionFront:
            return CameraDevicePositionFront;
            
        case AVCaptureDevicePositionUnspecified:
            return CameraDevicePositionUnspecified;
    }
}

+ (AVVideoCodecType)avVideoCodecTypeStringForCameraPickerVideoCodecType:(CameraPickerVideoCodecType)codecType {
    
    if (@available(iOS 11.0, *)) {
        
        switch (codecType) {
            case CameraPickerVideoCodecTypeHEVC:
                return AVVideoCodecTypeHEVC;
            case CameraPickerVideoCodecTypeH264:
                return AVVideoCodecTypeH264;
            case CameraPickerVideoCodecTypeJPEG:
                return AVVideoCodecTypeJPEG;
            case CameraPickerVideoCodecTypeAppleProRes4444:
                return AVVideoCodecTypeAppleProRes4444;
            case CameraPickerVideoCodecTypeAppleProres422:
                return AVVideoCodecTypeAppleProRes422;
            case CameraPickerVideoCodecTypeUnknown:
                return nil;
        }
    } else {
        
        switch (codecType) {
            case CameraPickerVideoCodecTypeHEVC:
                return AVVideoCodecHEVC;
            case CameraPickerVideoCodecTypeH264:
                return AVVideoCodecH264;
            case CameraPickerVideoCodecTypeJPEG:
                return AVVideoCodecJPEG;
                
            case CameraPickerVideoCodecTypeAppleProRes4444:
            case CameraPickerVideoCodecTypeAppleProres422:
            case CameraPickerVideoCodecTypeUnknown:
                /* Unavailable on iOS < 11 */
                return nil;
        }
    }
    
    return nil;
}

+ (CameraPickerVideoCodecType)cameraPickerVideoCodecTypeForAVVideoCodecType:(AVVideoCodecType)codecType {
    
    if ([codecType isEqualToString:AVVideoCodecTypeHEVC] ||
        [codecType isEqualToString:AVVideoCodecHEVC]) {
        return CameraPickerVideoCodecTypeHEVC;
        
    } else if ([codecType isEqualToString:AVVideoCodecTypeH264] ||
               [codecType isEqualToString:AVVideoCodecH264]) {
        return CameraPickerVideoCodecTypeH264;
        
    } else if ([codecType isEqualToString:AVVideoCodecTypeJPEG] ||
               [codecType isEqualToString:AVVideoCodecJPEG]) {
        return CameraPickerVideoCodecTypeJPEG;
        
    } else if ([codecType isEqualToString:AVVideoCodecTypeAppleProRes4444]) {
        return CameraPickerVideoCodecTypeAppleProRes4444;
        
    } else if ([codecType isEqualToString:AVVideoCodecTypeAppleProRes422]) {
        return CameraPickerVideoCodecTypeAppleProres422;
    }
    
    return CameraPickerVideoCodecTypeUnknown;
}

#pragma mark - Utils

- (void)dispatchOnSessionQueue:(void (^)(void))block {
    
    if (block) {
        dispatch_async(self.sessionQueue, ^{
            block();
        });
    }
}

- (void)dispatchSynchronouslyOnSessionQueue:(void (^)(void))block {
    
    if (block) {
        dispatch_sync(self.sessionQueue, ^{
            block();
        });
    }
}

/**
 *  @discussion This method performs given block on main queue serially if execution is on main queue already or dispatches it to main queue otherwise.
 */
+ (void)performBlockOnMainQueue:(void(^)(void))block {
    [NSThread isMainThread] ? block() : [[NSOperationQueue mainQueue] addOperationWithBlock:block];
}

+ (AVCaptureDevice *)videoCaptureDeviceForPreferredPosition:(AVCaptureDevicePosition)position {
    
    if (NSClassFromString(@"AVCaptureDeviceDiscoverySession")) {
        
        switch (position) {
                
            case AVCaptureDevicePositionBack: {
                
#warning Return AVCaptureDeviceTypeBuiltInDualCamera if possible when Apple fixed the Camera app issues
                /**
                 * AVCaptureDeviceTypeBuiltInDualCamera should have higher priority and be the first choice if possible.
                 * There is a bug in the native Camera app that makes it unusable: either exposure is broken or the capture session is entirely broken.
                 * That probably leaves incorrect shared private capture device state because transitioning from a broken Camera app to our Camera Picker breaks
                 * our capture device if we use the 'build in dual camera' device.
                 */
                AVCaptureDevice *captureDevice = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                                        mediaType:AVMediaTypeVideo position:position].devices.firstObject;
                if (captureDevice) {
                    return captureDevice;
                }
                return [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera]
                                                                              mediaType:AVMediaTypeVideo position:position].devices.firstObject;
            }
                
            case AVCaptureDevicePositionFront:
            case AVCaptureDevicePositionUnspecified: {
                return [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera,
                                                                                          AVCaptureDeviceTypeBuiltInTelephotoCamera,
                                                                                          AVCaptureDeviceTypeBuiltInDualCamera]
                                                                              mediaType:AVMediaTypeVideo position:position].devices.firstObject;
            }
        }
        
    } else {
        
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if ([device position] == position) {
                return device;
            }
        }
    }
    
    /* Fallback to the default camera */
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    return nil;
}

+ (AVCaptureDeviceInput *)frontFacingCameraDeviceInput {
    return [CameraPickerAVFoundationModel cameraDeviceInputForDevicePosition:AVCaptureDevicePositionFront];
}

+ (AVCaptureDeviceInput *)backFacingCameraDeviceInput {
    return [CameraPickerAVFoundationModel cameraDeviceInputForDevicePosition:AVCaptureDevicePositionBack];
}

+ (AVCaptureDeviceInput *)cameraDeviceInputForDevicePosition:(AVCaptureDevicePosition)devicePosition {
    
    NSError *error = nil;
    AVCaptureDevice *videoCaptureDevice = [CameraPickerAVFoundationModel videoCaptureDeviceForPreferredPosition:devicePosition];
    
    if ([videoCaptureDevice lockForConfiguration:&error]) {
        
        if ([videoCaptureDevice isLowLightBoostSupported]) {
            videoCaptureDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
        }
        
        if ([videoCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            videoCaptureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
        }
        
        if ([videoCaptureDevice isFocusModeSupported:CameraPickerAVFoundationModel.defaultFocusMode]) {
            videoCaptureDevice.focusMode = CameraPickerAVFoundationModel.defaultFocusMode;
        }
        
        if ([videoCaptureDevice isExposureModeSupported:CameraPickerAVFoundationModel.defaultExposureMode]) {
            videoCaptureDevice.exposureMode = CameraPickerAVFoundationModel.defaultExposureMode;
        }
        
        videoCaptureDevice.subjectAreaChangeMonitoringEnabled = YES;
        
        [videoCaptureDevice unlockForConfiguration];
    }
    
    /* Get the input device */
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    if (!error) {
        return deviceInput;
    } else {
        NSLog(@"Error getting capture device input %@", error);
    }
    return nil;
}

+ (AVCaptureDeviceInput *)microphoneInputDevice {
    
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Could not create audio device input: %@", error);
    }
    return audioDeviceInput;
}

+ (AVCaptureOutput *)createPhotoCaptureOutput {
    
    if (NSClassFromString(@"AVCapturePhotoOutput")) {
        
        AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
        photoOutput.highResolutionCaptureEnabled = YES;
        return photoOutput;
    } else {
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        return stillImageOutput;
    }
}

+ (AVCaptureMovieFileOutput *)createMovieFileOutput {
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    return movieFileOutput;
}

+ (AVCaptureFocusMode)defaultFocusMode {
    return AVCaptureFocusModeContinuousAutoFocus;
}

+ (AVCaptureExposureMode)defaultExposureMode {
    return AVCaptureExposureModeContinuousAutoExposure;
}

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetIG =
    [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetIG.appliesPreferredTrackTransform = YES;
    assetIG.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *igError = nil;
    thumbnailImageRef =
    [assetIG copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                    actualTime:NULL
                         error:&igError];
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

+ (NSURL *)temporaryDirectory {
    
    if (@available(iOS 10.0, *)) {
        return [[NSFileManager defaultManager] temporaryDirectory];
    } else {
        return [NSURL fileURLWithPath:NSTemporaryDirectory()];
    }
}

+ (NSString *)fileExtensionForCameraPickerCodecType:(CameraPickerVideoCodecType)codecType {
    
    switch (codecType) {
        case CameraPickerVideoCodecTypeJPEG:
            return @"jpeg";
            
        case CameraPickerVideoCodecTypeH264:
            return @"mp4";
            
        case CameraPickerVideoCodecTypeHEVC:
        case CameraPickerVideoCodecTypeAppleProRes4444:
        case CameraPickerVideoCodecTypeAppleProres422:
            return @"mov";
        case CameraPickerVideoCodecTypeUnknown:
            break;
    }
    return nil;
}

@end
