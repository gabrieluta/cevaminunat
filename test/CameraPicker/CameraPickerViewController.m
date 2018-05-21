//
//  CameraPickerViewController.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerViewController.h"

#import "CameraPickerAppearance.h"
#import "CameraPickerAVFoundationModel.h"
#import "CameraPickerOverlayView.h"
#import "CameraPickerPreviewView.h"
#import "CameraPickerResourceLoader.h"
#import "CameraPickerUIUtils.h"

#import "UIImage+CameraPicker.h"

NSString * const kCameraPickerPickedImageData = @"kCameraPickerPickedImageData";
NSString * const kCameraPickerMediaType       = @"kCameraPickerMediaType";
NSString * const kCameraPickerMediaURL        = @"kCameraPickerMediaURL";
NSString * const kCameraPickerMediaWasEdited  = @"kCameraPickerMediaWasEdited";

#define BLUR_EFFECT_VIEW_TAG 123

@import MobileCoreServices;

@interface CameraPickerViewController ()<CameraOverlayViewDelegate,
                                         CameraPickerAVFoundationModelDelegate>

@property (nonatomic) CameraPickerAVFoundationModel *videoModel;
@property (nonatomic) NSMutableDictionary *infoDictionary;
@property (nonatomic) NSArray <NSNumber *> *availableCaptureModes;
@property (nonatomic) NSData *originalImageData;
@property (nonatomic) NSData *editedImageData;
@property (nonatomic) CameraPickerPhotoSize photoSize;
@property (nonatomic) BOOL userDidFocus;

/* UI */
@property (nonatomic, weak) CameraPickerPreviewView *previewView;
@property (nonatomic) CameraPickerOverlayView *overlayView;
@property (nonatomic) UIDeviceOrientation imageCaptureOrientation;

/* Gesture recognizers */
@property (nonatomic) UITapGestureRecognizer *focusAndExposeGestureRecognizer;
@property (nonatomic) BOOL dismissingPresentedViewController;

@end

@implementation CameraPickerViewController

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.captureMode = CameraPickerCaptureModePhoto;
        self.infoDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setMediaTypes:(NSArray<NSString *> *)mediaTypes {
    
    _mediaTypes = mediaTypes;
    
    NSMutableArray <NSNumber *> *availableCaptureModes = [NSMutableArray array];
    
    if ([mediaTypes containsObject:(__bridge NSString *)kUTTypeImage]) {
        [availableCaptureModes addObject:@(CameraPickerCaptureModePhoto)];
    }
    
    self.availableCaptureModes = availableCaptureModes;
}

- (void)setAllowsPhotoEditing:(BOOL)allowsPhotoEditing {
    _allowsPhotoEditing = allowsPhotoEditing;
    self.overlayView.allowsPhotoEditing = allowsPhotoEditing;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addObservers];
    
    /* Set up the preview view */
    CameraPickerPreviewView *previewView = [[CameraPickerPreviewView alloc] init];
    self.previewView = previewView;
    [self.previewView.resumeButton addTarget:self action:@selector(resumeInterruptedSession:) forControlEvents:UIControlEventTouchUpInside];
    
    /* Setup preview view UI - pin margins to parent margins */
    [self.view addSubview:previewView];
    previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [CameraPickerUIUtils pinView:previewView toMarginsOfView:previewView.superview];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self.dismissingPresentedViewController) {
        
        /*
         * A presented ViewController was dismissed (e.g. ImageEditor)
         * No need to do anything.
         */
        self.dismissingPresentedViewController = NO;
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    
    switch (self.videoModel.setupResult) {
            
        case CameraPickerSetupResultSuccess: {
            
            /* Only setup observers and start the session running if setup succeeded. */
            
            /* Set preview layer video orientation */
            AVCaptureVideoOrientation initialVideoOrientation;
            if ([self viewControllerIsIndependetOfOrientation]) {
                initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            } else {
                initialVideoOrientation = CameraPickerUIUtils.sharedInstance.currentVideoOrientation;
            }
            self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation;
            
            /* Start the session and prepare the overlay view */
            [self.videoModel startRunning];
            [self setupOverlayView];
        } break;
            
        case CameraPickerSetupResultCameraNotAuthorized: {
            [CameraPickerUIUtils displayGotoSettingsAlerInAbsenceOfCameraPermissionFromViewController:self];
        } break;
            
        case CameraPickerSetupResultSessionConfigurationFailed: {
            [CameraPickerUIUtils displayUnableToCaptureMediaAlertFromViewController:self completion:^(UIAlertAction *action) {
                [weakSelf destroyCapturedVideoIfNeeded];
                [weakSelf.delegate cameraPickerControllerDidCancel:weakSelf];
            }];
        } break;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.videoModel stopRunning];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotate {
    
    if (![self viewControllerIsIndependetOfOrientation]) {
        return YES;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    if (![self viewControllerIsIndependetOfOrientation]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupOverlayView {
    
    /* Setup the overlayView */
    CameraPickerOverlayView *overlayView = self.overlayView;
    if (!overlayView) {
        overlayView = [[CameraPickerOverlayView alloc] init];
        self.overlayView = overlayView;
        overlayView.delegate = self;
        [self.view addSubview:overlayView];
        overlayView.allowsPhotoEditing = self.allowsPhotoEditing;
        overlayView.availableCaptureModes = self.availableCaptureModes;
        overlayView.captureMode = self.captureMode;
        overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        [CameraPickerUIUtils pinView:overlayView toMarginsOfView:overlayView.superview];
        [self setupOverlayViewForCurrentDevice];
        [overlayView prepareForPreCaptureState];
        [self addFocusAndExposureGestureRecognizer];
    }
    [self prepareForCurrentDeviceOrientation];
}

- (void)setupOverlayViewForCurrentDevice {
    
    BOOL flashAvailable = [self.videoModel currentCameraDeviceHasFlash];
    if (flashAvailable != self.overlayView.flashAvailable) {
        self.overlayView.flashAvailable = flashAvailable;
    }
    BOOL switchCameraButtonAvailable = ([CameraPickerAVFoundationModel uniqueDevicePositionsCount] > 1);
    if (self.overlayView.switchCameraButtonAvailable != switchCameraButtonAvailable) {
        self.overlayView.switchCameraButtonAvailable = switchCameraButtonAvailable;
    }
    
    self.overlayView.availableFlashModes = [self.videoModel availableFlashModesForCurrentVideoDevice];
    
    CameraDevicePosition cameraPosition = self.videoModel.currentCameraPosition;
    if (cameraPosition == CameraDevicePositionUnspecified) {
        self.overlayView.cameraPosition = CameraDevicePositionFront;
    }
    if (self.overlayView.cameraPosition != cameraPosition) {
        self.overlayView.cameraPosition = cameraPosition;
    }
}

#pragma mark - Capture Session Management

- (void)resumeInterruptedSession:(id)sender {
    
    __weak __typeof(self) weakSelf = self;
    [self.videoModel tryToResuemCaptureSessionWithCompletion:^(BOOL sessionIsRunning) {
        
        if (sessionIsRunning) {
            [weakSelf.previewView setShowResumeButton:NO animated:YES];
        } else {
            [CameraPickerUIUtils displayUnableToResumeSessionAlertFromViewController:weakSelf completion:^(UIAlertAction *action) {
                
                [weakSelf destroyCapturedVideoIfNeeded];
                [weakSelf.delegate cameraPickerControllerDidCancel:weakSelf];
            }];
        }
    }];
}

- (void)changeCaptureMode:(CameraPickerCaptureMode)captureMode {
    
    __weak __typeof(self) weakSelf = self;
    
    self.overlayView.interactionWithUIEnabled = NO;
    self.previewView.backgroundColor = [UIColor clearColor];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    blurEffectView.frame = self.previewView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.tag = BLUR_EFFECT_VIEW_TAG;
    
    [UIView transitionWithView:weakSelf.previewView
                      duration:[CameraPickerAppearance captureModeChangeAnimatioDuration]
                       options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        [weakSelf.previewView insertSubview:blurEffectView belowSubview:weakSelf.overlayView];
                    }
                    completion:^(BOOL finished) {
                        [[weakSelf.previewView viewWithTag:BLUR_EFFECT_VIEW_TAG] removeFromSuperview];
                    }];
    
    void (^completion)(BOOL) = ^(BOOL success){
        weakSelf.overlayView.interactionWithUIEnabled = YES;
    };
    
    [self.videoModel changeCaptureMode:captureMode completion:completion];
}

#pragma mark Device Configuration

- (void)toggleCamera {
    
    __weak __typeof(self) weakSelf = self;
    self.overlayView.interactionWithUIEnabled = NO;
    
    [self hideFocusMarker];
    
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    blurEffectView.frame = self.previewView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.tag = BLUR_EFFECT_VIEW_TAG;
    
    [UIView transitionWithView:weakSelf.previewView
                      duration:[CameraPickerAppearance cameraSwitchAnimationDuration]
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations: ^{
                        [weakSelf.previewView insertSubview:blurEffectView belowSubview:weakSelf.overlayView];
                    }
                    completion:^(BOOL finished) {
                        [[weakSelf.previewView viewWithTag:BLUR_EFFECT_VIEW_TAG] removeFromSuperview];
                    }];
    
    [self.videoModel toggleCameraWithCompletion:^{
        
        weakSelf.overlayView.interactionWithUIEnabled = YES;
        [weakSelf setupOverlayViewForCurrentDevice];
    }];
}

#pragma mark - Focus

- (void)addFocusAndExposureGestureRecognizer {
    
    self.overlayView.userInteractionEnabled = YES;
    UITapGestureRecognizer *focusAndExposeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusAndExposeTap:)];
    self.focusAndExposeGestureRecognizer = focusAndExposeTap;
    focusAndExposeTap.numberOfTapsRequired = 1;
    [self.overlayView addGestureRecognizer:focusAndExposeTap];
}

- (void)removeFocusAndExposureGestureRecognizer {
    
    if (self.focusAndExposeGestureRecognizer) {
        [self.overlayView removeGestureRecognizer:self.focusAndExposeGestureRecognizer];
    }
}

- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer {
    
    if ([self.videoModel isFocusPointOfInterestSupported]) {
        
        CGPoint pointInView = [gestureRecognizer locationInView:gestureRecognizer.view];
        CGPoint devicePoint = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:pointInView];
        
        [self hideFocusMarker];
        [self showFocusMarkerAtPoint:pointInView withFadeOutDuration:3.0 completion:nil];
        self.userDidFocus = YES;
        [self.videoModel focusAndExposePointOfInterest:devicePoint];
    }
}

- (UIView *)focusMarker {
    return [self.view viewWithTag:1213];
}

- (UIView *)newFocusMarker {
    UIImageView *focusMarker = [[UIImageView alloc] initWithImage:[CameraPickerResourceLoader imageNamed:@"focusMarker"]];
    focusMarker.tag = 1213;
    return focusMarker;
}

- (void)showFocusMarkerAtPoint:(CGPoint)point
           withFadeOutDuration:(CGFloat)fadeOutDuration
                    completion:(void (^)(void))completionHandler {
    
    [self hideFocusMarker];
    
    UIView *focusMarker = [self newFocusMarker];
    focusMarker.alpha = 0.0f;
    focusMarker.center = point;
    [self.view addSubview:focusMarker];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         focusMarker.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:fadeOutDuration
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              focusMarker.alpha = 0.25f;
                                          } completion:^(BOOL finished) {
                                              
                                              if (completionHandler) {
                                                  completionHandler();
                                              }
                                          }];
                     }];
}

- (void)hideFocusMarker {
    /* Hide focus marker if already shown */
    [[self focusMarker] removeFromSuperview];
}

- (void)moveFocusMarkerIfShownAtPoint:(CGPoint)focusMarkCenter {
    [self moveFocusMarkerIfShownAtPoint:focusMarkCenter completion:nil];
}

- (void)moveFocusMarkerIfShownAtPoint:(CGPoint)focusMarkCenter
                           completion:(void (^)(void))completionHandler {
    
    UIView *shownFocusMarker = [self focusMarker];
    
    if (shownFocusMarker) {
        
        [UIView animateWithDuration:0.1
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             shownFocusMarker.center = focusMarkCenter;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished) {
                             if (completionHandler) {
                                 completionHandler();
                             }
                         }];
    }
}

#pragma mark Capturing Photos

- (void)capturePhoto {
    
    /* Disable user interaction during photo capturing */
    self.overlayView.interactionWithUIEnabled = NO;
    [self.videoModel changeVideoOrientationIfNeeded];
    
    __weak __typeof(self) weakSelf = self;
    [self.videoModel capturePhotoWithAnimations:^{
        weakSelf.previewView.videoPreviewLayer.opacity = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.previewView.videoPreviewLayer.opacity = 1.0;
        }];
    }
                                     completion:^(NSError *error, NSData *imageData, UIImage *previewImage) {
                                         
                                         if (!error) {
                                             [weakSelf didFinishCapturingImageWithData:imageData preview:previewImage];
                                         } else {
                                             [weakSelf didFinishCapturingImageWithData:nil preview:nil];
                                         }
                                     }];
}

- (void)didFinishCapturingImageWithData:(NSData *)imageData preview:(UIImage *)previewImage {
    
    if (imageData && previewImage) {
        
        self.originalImageData = imageData;
        self.infoDictionary[kCameraPickerMediaType] = (__bridge NSString*)kUTTypeImage;
        self.infoDictionary[kCameraPickerPickedImageData] = imageData;
        self.infoDictionary[kCameraPickerMediaWasEdited] = @(NO);
        [self.overlayView prepareForCapturedPhotoState:previewImage];
        
        [self hideFocusMarker];
        [self removeFocusAndExposureGestureRecognizer];
        
        /*
         * We can stop the session for performance reasons, since the preview layer will be obscured by the overlay
         * The user will be presented with a screen from which to take further actions on the captured photo
         * Unless the user returns to a pre-capture state, there is no need for the session to continue running
         */
        [self.videoModel stopRunning];
        
    } else {
        
        [CameraPickerUIUtils displayUnableToCapturePhotoAlertFromViewController:self completion:^(UIAlertAction *action) {
            
#warning Remove session restarting when the Camera app issues are fixed by Apple
            /**
             * There is a bug in the native Camera app that makes it unusable: either exposure is broken or the capture session is entirely broken.
             * That probably leaves incorrect shared private capture device state because transitioning from a broken Camera app to our Camera Picker
             * breaks our capture session.
             * At this point self.viewModel.session.isRunning == YES but because of the before-mentioned bug it needs a restart.
             */
            [self.videoModel stopRunning];
            [self.videoModel startRunning];
            
            [self.overlayView prepareForPreCaptureState];
        }];
    }
    self.overlayView.interactionWithUIEnabled = YES;
}

#pragma mark Recording Movies
//
//- (void)toggleMovieRecording {
//
//    __weak __typeof(self) weakSelf = self;
//
//    self.videoModel.startedRecordingVideoBlock = ^{
//        weakSelf.overlayView.recordingVideo = YES;
//    };
//
//    self.videoModel.finishedRecordingVideoBlock = ^(BOOL success, NSError *error, NSURL *videoURL) {
//
//        if (success) {
//
//            weakSelf.infoDictionary[kCameraPickerMediaType] = (__bridge NSString*)kUTTypeMovie;
//            weakSelf.infoDictionary[kCameraPickerMediaURL] = videoURL;
//            weakSelf.overlayView.recordingVideo = NO;
//
//            UIImage *videoThumbnail = [CameraPickerAVFoundationModel thumbnailImageForVideo:videoURL atTime:0];
//            [weakSelf.overlayView prepareForCapturedVideoState:videoThumbnail];
//
//            [weakSelf hideFocusMarker];
//            [weakSelf removeFocusAndExposureGestureRecognizer];
//
//            /*
//             * We can stop the session for performance reasons, since the preview layer will be obscured by the overlay
//             * The user will be presented with a screen from which to take further actions on the captured photo
//             * Unless the user returns to a pre-capture state, there is no need for the session to continue running
//             */
//            [weakSelf.videoModel stopRunning];
//
//        } else {
//
//            [CameraPickerUIUtils displayUnableToSaveVideoAlertFromViewController:weakSelf completion:^(UIAlertAction *action) {
//                [weakSelf.overlayView prepareForPreCaptureState];
//                weakSelf.overlayView.captureMode = CameraPickerCaptureModeMovie;
//            }];
//        }
//    };
//
//    [self.videoModel toggleMovieRecoring];
//}

#pragma mark - Flash

- (void)changeFlashMode:(CameraFlashMode)flashMode {
    
    __weak __typeof(self) weakSelf = self;
    [self.videoModel changeFlashMode:flashMode completion:^(CameraFlashMode flashMode) {
        weakSelf.overlayView.flashMode = flashMode;
    }];
}

#pragma mark - Codec Management

/* @return an array of CameraPickerVideoCodecType wrapped as NSNumbers */
+ (NSArray <NSNumber *> *)availablePhotoCaptureCodecs {
    return CameraPickerAVFoundationModel.availablePhotoCaptureCodecs;
}

#pragma mark - Notifications

- (void)addObservers {
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)removeObservers {
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

#pragma mark - Orientation Handling

- (void)orientationDidChange:(NSNotification *)notification {
    [self prepareForCurrentDeviceOrientation];
}

- (void)prepareForCurrentDeviceOrientation {
    
    UIDeviceOrientation currentLayoutOrientation = CameraPickerUIUtils.sharedInstance.currentLayoutOrientation;
    if ([self viewControllerIsIndependetOfOrientation]) {
        [self.overlayView prepareForDeviceOrientation:currentLayoutOrientation];
    } else {
        AVCaptureConnection *previewLayerConnection = self.previewView.videoPreviewLayer.connection;
        if([previewLayerConnection isVideoOrientationSupported]) {
            previewLayerConnection.videoOrientation = CameraPickerUIUtils.sharedInstance.currentVideoOrientation;
        }
    }
}

- (BOOL)viewControllerIsIndependetOfOrientation {
    return UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad;
}

#pragma mark - CameraPickerAVFoundationModelDelegate

- (void)cameraDeviceDidBecomeAvailableForAVFoundationModel:(CameraPickerAVFoundationModel *)avFoundationModel {
    [self setupOverlayViewForCurrentDevice];
}

- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeCaptureSessionRunningStatus:(BOOL)isSessionRunning {
    self.overlayView.interactionWithUIEnabled = isSessionRunning;
}

- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didInterruptSessionWithReason:(CaptureSessionInterruptionReason)interruptionReason {
    
    switch (interruptionReason) {
            
        case CaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
        case CaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
        case CaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
        case CaptureSessionInterruptionReasonUnknown:
            
            /* If the app is in background, the capture session will be restarted when the interruption ends after the forground transition */
            if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground) {
                /* Show a button to enable the user to try to resume the capture session. */
                [self.previewView setShowResumeButton:YES animated:YES];
                break;
            }
            
        case CaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
            /* Do nothing. The capture session will be restarted when the interruption ends after the forground transition */
            break;
            
        case CaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure:
            /* Show a label to inform the user that the camera is unavailable. */
            [self.previewView setShowCameraUnavailableLabel:YES animated:YES];
    }
}

- (void)avFoundationModelDidEndSessionInterruption:(CameraPickerAVFoundationModel *)model  {
    [self.previewView setShowResumeButton:NO animated:YES];
    [self.previewView setShowCameraUnavailableLabel:NO animated:YES];
}

- (void)avFoundationModelDidChangeVideoSubjectArea:(CameraPickerAVFoundationModel *)model {
    
    /*
     * The user moved the device substantially.
     */
    
    self.userDidFocus = NO;
    
    if ([self.videoModel isFocusPointOfInterestSupported]) {
        
        CGPoint viewPointToFocus = self.previewView.center;
        CGPoint devicePointToFocus = [self.previewView.videoPreviewLayer captureDevicePointOfInterestForPoint:viewPointToFocus];
        
        __weak __typeof(self) weakSelf = self;
        [self showFocusMarkerAtPoint:self.videoModel.focusPointOfInterest
                 withFadeOutDuration:2.0f
                          completion:^{
                              [weakSelf hideFocusMarker];
                          }];
        [self.videoModel focusAndExposePointOfInterest:devicePointToFocus];
    }
}

- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeFocusPointOfInterest:(CGPoint)focusPointOfInterest {
    
    /* Focus point of interest changed automatically and not by user tap. */
    self.userDidFocus = NO;
    
    if ([self.videoModel isFocusPointOfInterestSupported]) {
        
        __weak __typeof(self) weakSelf = self;
        [self showFocusMarkerAtPoint:self.videoModel.focusPointOfInterest
                 withFadeOutDuration:2.0f
                          completion:^{
                              [weakSelf hideFocusMarker];
                          }];
    }
    
}

- (void)avFoundationModel:(CameraPickerAVFoundationModel *)model didChangeAdjustingFocus:(BOOL)isAdjustingFocus {
    
    if (self.userDidFocus) {
        /* Do nothing if the user tapped to focus
         * and the focus hasn't since changed automatically.
         */
        return;
    }
    
    if (!isAdjustingFocus) {
        [self hideFocusMarker];
    } else {
        if ([self.videoModel isFocusPointOfInterestSupported]) {
            
            __weak __typeof(self) weakSelf = self;
            [self showFocusMarkerAtPoint:self.videoModel.focusPointOfInterest
                     withFadeOutDuration:3.0f
                              completion:^{
                                  [weakSelf hideFocusMarker];
                              }];
        }
    }
}

#pragma mark -  CameraOverlayViewDelegate

/* pre capture actions */

- (void)cameraOverlayViewDidTapCancelButton:(CameraPickerOverlayView *)cameraOverlayView {
    [self destroyCapturedVideoIfNeeded];
    [self.delegate cameraPickerControllerDidCancel:self];
}

- (void)cameraOverlayViewDidTapSwitchCameraButton:(CameraPickerOverlayView *)cameraOverlayView {
    
    /* Sanity check if switch camera button is available */
    if ([CameraPickerAVFoundationModel uniqueDevicePositionsCount] < 2) {
        self.overlayView.switchCameraButtonAvailable = NO;
    } else {
        [self toggleCamera];
    }
}

- (void)cameraOverlayViewDidTapCaptureButton:(CameraPickerOverlayView *)cameraOverlayView {
    
    if (self.captureMode == CameraPickerCaptureModePhoto) {
        [self capturePhoto];
    }
}

- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView didChangeCaptureMode:(CameraPickerCaptureMode)captureMode {
    
    /* At this point we can guarantee that photo capture and video capture are available.
     * Sound for video is not guaranteed becuase the user might have denied access to microphone
     */
    self.captureMode = captureMode;
    self.overlayView.captureMode = captureMode;
    [self changeCaptureMode:captureMode];
    
    [self hideFocusMarker];
}

- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView didChangeCameraFlashMode:(CameraFlashMode)flashMode {
    [self changeFlashMode:flashMode];
}

/* post capture actions*/

- (void)cameraOverlayViewDidTapDoneButton:(CameraPickerOverlayView *)cameraOverlayView {
    if (!self.setupForAvatarSelection || [self editedImageIsSquare]) {
        [self.delegate cameraPickerController:self didFinishPickingMediaWithInfo:self.infoDictionary];
    } else {
//        [self presentImageEditor:YES];
    }
}

- (void)cameraOverlayViewDidTapRetakeButton:(CameraPickerOverlayView *)cameraOverlayView {
    
    [self destroyCapturedVideoIfNeeded];
    
    self.infoDictionary = [NSMutableDictionary dictionary];
    self.originalImageData = nil;
    self.editedImageData = nil;
    self.photoSize = CameraPickerPhotoSizeOriginal;
    [self.overlayView prepareForPreCaptureState];
    [self prepareForCurrentDeviceOrientation];
    [self addFocusAndExposureGestureRecognizer];
    
    /* Since the user wants to return to capture media, we have to
     * restart the session, which was stopped when entering a post-capture state
     */
    [self.videoModel startRunning];
}

- (void)cameraOverlayView:(CameraPickerOverlayView *)cameraOverlayView
       didChangePhotoSize:(CameraPickerPhotoSize)photoSize {
    
    UIImage *resizedImage = [UIImage camp_imageWithCameraPickerPhotoSize:photoSize forImageData:self.editedImageData];
    if (resizedImage) {
        
        NSData *resizedImageData = [[NSMutableData alloc] init];
        if ([resizedImage camp_writeJPEGToMemory:&resizedImageData withQuality:1.0]) {
            self.photoSize = photoSize;
            self.infoDictionary[kCameraPickerPickedImageData] = resizedImageData;
            [self.overlayView updateCapturedPhoto:resizedImage withSize:self.photoSize];
        }
    }
}

- (void)cameraOverlayViewDidTapEditPhotoButton:(CameraPickerOverlayView *)cameraOverlayView {
//    [self presentImageEditor:NO];
}

#pragma mark - Utils

- (UIImage *)originalImage {
    return [UIImage imageWithData:self.originalImageData];
}

- (NSData *)editedImageData {
    
    if (_editedImageData) {
        return _editedImageData;
    }
    return self.originalImageData;
}

- (UIImage *)editedImage {
    
    if (!self.editedImageData) {
        return self.originalImage;
    }
    
    return [UIImage imageWithData:self.editedImageData];
}

- (BOOL)editedImageIsSquare {
    
    UIImage *editedImage = self.editedImage;
    if (editedImage.size.height == editedImage.size.width) {
        return YES;
    }
    return NO;
}

- (void)destroyCapturedVideoIfNeeded {
    
    NSURL *capturedVideoURL = self.infoDictionary[kCameraPickerMediaURL];
    if (capturedVideoURL) {
        [CameraPickerAVFoundationModel destroyFileWithURL:capturedVideoURL];
    }
}

@end
