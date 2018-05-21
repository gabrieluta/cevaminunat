//
//  CameraPickerUIUtils.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerUIUtils.h"
#import "CameraPickerResourceLoader.h"

@interface CameraPickerUIUtils()

@property (nonatomic, assign) UIDeviceOrientation previousLayoutOrientation;

@end

@implementation CameraPickerUIUtils

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _previousLayoutOrientation = UIDeviceOrientationUnknown;
    }
    return self;
}

#pragma mark - Orientation Handling

/** Provides a singleton instance for this class */
+ (instancetype)sharedInstance {
    
    static CameraPickerUIUtils *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CameraPickerUIUtils alloc] init];
    });
    
    return instance;
}

/**
 This is needed because UIDeviceOrientation can also have values
 that don't make sense for layout (see isIgnorableDeviceOrientation:)
 */
- (UIDeviceOrientation)currentLayoutOrientation {
    
    if ([CameraPickerUIUtils isIgnorableDeviceOrientation:[UIDevice currentDevice].orientation]) {
        if ([CameraPickerUIUtils isIgnorableDeviceOrientation:self.previousLayoutOrientation]) {
            if ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) {
                return UIDeviceOrientationPortrait;
            } else {
                return UIDeviceOrientationLandscapeLeft;
            }
        } else {
            return self.previousLayoutOrientation;
        }
    }
    
    self.previousLayoutOrientation = [UIDevice currentDevice].orientation;
    return self.previousLayoutOrientation;
}

+ (BOOL)isIgnorableDeviceOrientation:(UIDeviceOrientation)orientation {
    
    switch(orientation) {
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            //        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationUnknown: {
            return YES;
        }
        default:
            return NO;
    }
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
    AVCaptureVideoOrientation videoOrientation = [CameraPickerUIUtils videoOrientation:[self currentLayoutOrientation]];
    return videoOrientation;
}

+ (AVCaptureVideoOrientation)videoOrientation:(UIDeviceOrientation)orientation {
    
    switch (orientation) {
            
        case UIDeviceOrientationPortrait: return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown: return AVCaptureVideoOrientationPortraitUpsideDown;
            
            /**
             @constant AVCaptureVideoOrientationLandscapeRight
             Indicates that video should be oriented horizontally, home button on the right.
             
             @constant UIDeviceOrientationLandscapeLeft
             Device oriented horizontally, home button on the right
             */
        case UIDeviceOrientationLandscapeLeft: return AVCaptureVideoOrientationLandscapeRight;
            /*
             @constant AVCaptureVideoOrientationLandscapeLeft
             Indicates that video should be oriented horizontally, home button on the left.
             
             @constant UIDeviceOrientationLandscapeLeft
             Device oriented horizontally, home button on the left
             */
        case UIDeviceOrientationLandscapeRight: return AVCaptureVideoOrientationLandscapeLeft;
        default: return AVCaptureVideoOrientationPortrait;
    }
}

- (CGImagePropertyOrientation)currentImageOrientation {
    
    switch(self.currentLayoutOrientation) {
            
        case UIDeviceOrientationPortrait:
            return kCGImagePropertyOrientationUp;
        case UIDeviceOrientationPortraitUpsideDown:
            return kCGImagePropertyOrientationDown;
        case UIDeviceOrientationLandscapeLeft:
            return kCGImagePropertyOrientationRight;
        case UIDeviceOrientationLandscapeRight:
            return kCGImagePropertyOrientationLeft;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            break;
    }
    
    return kCGImagePropertyOrientationUp;
}

#pragma mark - Alerts

+ (void)displayGotoSettingsAlerInAbsenceOfCameraPermissionFromViewController:(UIViewController *)viewController {
    
    NSString *alertTitle = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerCameraPermissionAlertTitle"];
    NSString *alertMessage = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerCameraPermissionAlertMessage"];
    
    [CameraPickerUIUtils displayGotoSettingsAlert:alertTitle
                                             message:alertMessage
                                  fromViewController:viewController];
}

+ (void)displayGotoSettingsAlert:(NSString *)title
                         message:(NSString *)message
              fromViewController:(UIViewController *)viewController {
    
    void (^displayAlertBlock)(void) = ^{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:[CameraPickerResourceLoader localizedStringWithName:@"lOK"]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction* alertAction) {
                                                                  
                                                              }];
        
        UIAlertAction *positiveAction = [UIAlertAction actionWithTitle:[CameraPickerResourceLoader localizedStringWithName:@"lGoToSettings"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction* alertAction) {
                                                                   [CameraPickerUIUtils goToSettings];
                                                               }];
        
        [alertController addAction:dismissAction];
        [alertController addAction:positiveAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    };
    
    if ([NSThread isMainThread]) {
        displayAlertBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            displayAlertBlock();
        });
    }
}

+ (void)displayUnableToCaptureMediaAlertFromViewController:(UIViewController *)viewController
                                                completion:(void (^ __nullable)(UIAlertAction *action))completion {
    
    NSString *alertTitle = nil;
    NSString *alertMessage = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerUnableToCaptureMediaAlertMessage"];
    
    [CameraPickerUIUtils displayErrorAlertWithTitle:alertTitle
                                               message:alertMessage
                                    fromViewController:viewController
                                            completion:completion];
}

+ (void)displayUnableToCapturePhotoAlertFromViewController:(UIViewController *)viewController
                                                completion:(void (^ __nullable)(UIAlertAction *action))completion {
    
    NSString *alertTitle = nil;
    NSString *alertMessage = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerUnableToCapturePhotoAlertMessage"];
    
    [CameraPickerUIUtils displayErrorAlertWithTitle:alertTitle
                                               message:alertMessage
                                    fromViewController:viewController
                                            completion:completion];
}

+ (void)displayUnableToResumeSessionAlertFromViewController:(UIViewController *)viewController
                                                 completion:(void (^ __nullable)(UIAlertAction *action))completion {
    
    NSString *alertTitle = nil;
    NSString *alertMessage = [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerUnableToResumeSession"];
    
    [CameraPickerUIUtils displayErrorAlertWithTitle:alertTitle
                                               message:alertMessage
                                    fromViewController:viewController
                                            completion:completion];
    
}


+ (void)displayErrorAlertWithTitle:(NSString *)alertTitle
                           message:(NSString *)alertMessage
                fromViewController:(UIViewController *)viewController
                        completion:(void (^ __nullable)(UIAlertAction *action))completion {
    
    void (^displayAlertBlock)(void) = ^{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                 message:alertMessage
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:[CameraPickerResourceLoader localizedStringWithName:@"lOK"]
                                                           style:UIAlertActionStyleDefault
                                                         handler:completion];
        [alertController addAction:okAction];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    };
    
    if ([NSThread isMainThread]) {
        displayAlertBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            displayAlertBlock();
        });
    }
}

+ (void)goToSettings {
    [CameraPickerUIUtils openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - Logging utils

+ (NSString *)deviceOrientationAsString:(UIDeviceOrientation)orientation {
    
    if (orientation == UIDeviceOrientationPortrait) {
        return @"UIDeviceOrientationPortrait";
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        return @"UIDeviceOrientationPortraitUpsideDown";
    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
        return @"UIDeviceOrientationLandscapeLeft";
    } else if (orientation == UIDeviceOrientationLandscapeRight) {
        return @"UIDeviceOrientationLandscapeRight";
    } else if (orientation == UIDeviceOrientationFaceUp) {
        return @"UIDeviceOrientationFaceUp";
    } else if (orientation == UIDeviceOrientationFaceDown) {
        return @"UIDeviceOrientationFaceDown";
    } else if (orientation == UIDeviceOrientationUnknown) {
        return @"UIDeviceOrientationUnknown";
    } else {
        return @"ORIENTATION IMPOSSIBLE CASE!";
    }
}

#pragma mark - Autolayout Utils

+ (void)pinView:(UIView *)aView toMarginsOfView:(UIView *)anotherView {
    
    NSLayoutConstraint *topConstraint = [aView.topAnchor constraintEqualToAnchor:anotherView.topAnchor];
    NSLayoutConstraint *bottomConstraint = [aView.bottomAnchor constraintEqualToAnchor:anotherView.bottomAnchor];
    NSLayoutConstraint *leadingConstraint = [aView.leadingAnchor constraintEqualToAnchor:anotherView.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [aView.trailingAnchor constraintEqualToAnchor:anotherView.trailingAnchor];
    [NSLayoutConstraint activateConstraints:@[topConstraint, bottomConstraint, leadingConstraint, trailingConstraint]];
}

#pragma mark - Helpers

+ (void)openURL:(NSURL *)anURL {
    
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:anURL options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:anURL];
    }
}

@end

