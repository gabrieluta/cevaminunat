//
//  CameraPickerUIUtils.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import UIKit;

@interface CameraPickerUIUtils : NSObject

#pragma mark - Orientation Handling

+ (instancetype)sharedInstance;
- (UIDeviceOrientation)currentLayoutOrientation;
- (AVCaptureVideoOrientation)currentVideoOrientation;
- (CGImagePropertyOrientation)currentImageOrientation;

#pragma mark - Alerts

+ (void)displayGotoSettingsAlerInAbsenceOfCameraPermissionFromViewController:(UIViewController *)viewController;

+ (void)displayGotoSettingsAlert:(NSString *)title
                         message:(NSString *)message
              fromViewController:(UIViewController *)viewController;

+ (void)displayUnableToCaptureMediaAlertFromViewController:(UIViewController *)viewController
                                                completion:(void (^)(UIAlertAction *action))completion;

+ (void)displayUnableToCapturePhotoAlertFromViewController:(UIViewController *)viewController
                                                completion:(void (^)(UIAlertAction *action))completion;

+ (void)displayUnableToResumeSessionAlertFromViewController:(UIViewController *)viewController
                                                 completion:(void (^)(UIAlertAction *action))completion;

+ (void)displayErrorAlertWithTitle:(NSString *)alertTitle
                           message:(NSString *)alertMessage
                fromViewController:(UIViewController *)viewController
                        completion:(void (^)(UIAlertAction *action))completion;

#pragma mark - Logging utils

// Orientation
+ (NSString *)deviceOrientationAsString:(UIDeviceOrientation)orientation;

#pragma mark - Autolayout Utils

+ (void)pinView:(UIView *)aView toMarginsOfView:(UIView *)anotherView;

#pragma mark - Helpers

+ (void)openURL:(NSURL *)anURL;

@end

