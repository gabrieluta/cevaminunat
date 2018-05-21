//
//  CameraPickerViewController.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerOverlayView.h"

@import UIKit;

extern NSString * const kCameraPickerPickedImageData;
extern NSString * const kCameraPickerMediaType;
extern NSString * const kCameraPickerMediaURL;
extern NSString * const kCameraPickerMediaWasEdited;

@class CameraPickerViewController;

@protocol CameraPickerViewControllerDelegate <NSObject>

- (void)cameraPickerController:(CameraPickerViewController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info;
- (void)cameraPickerControllerDidCancel:(CameraPickerViewController *)picker;

@end

@interface CameraPickerViewController : UIViewController

@property (nonatomic, weak)   id<CameraPickerViewControllerDelegate> delegate;
@property (nonatomic, assign) CameraPickerCaptureMode captureMode; // default is CameraPickerCaptureModePhoto
@property (nonatomic, copy)   NSArray<NSString *> *mediaTypes;
@property (nonatomic, assign) BOOL allowsPhotoEditing; // default is YES
@property (nonatomic, assign) BOOL setupForAvatarSelection;

/* Codec Management */
+ (NSArray <NSNumber *> *)availablePhotoCaptureCodecs;

@end
