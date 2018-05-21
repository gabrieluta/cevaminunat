//
//  ImagePickerController.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import Photos;
@import UIKit;

@class ImagePickerController;

/* Image picker presenter options */
extern NSString * const kImagePickerSourceType;
extern NSString * const kImagePickerCameraCaptureMode;
extern NSString * const kImagePickerAllowsEditing;
extern NSString * const kImagePickerMediaTypes;
extern NSString * const kImagePickerSetupForAvatarSelection;

/* Returned media version */
extern NSString * const kImagePickerReturnedMediaVersion;
/* Appearance */
extern NSString * const kImagePickerHorizontalMargin;
/* Maximum number of selection */
extern NSString * const kImagePickerMaximumNumberOfSelection;

typedef NS_ENUM(NSInteger, PSAImagePickerReturnedMediaVersion) {
    PSAImagePickerReturnedMediaVersionCurrent = 1,
    PSAImagePickerReturnedMediaVersionOriginal
};

@protocol ImagePickerControllerDelegate <NSObject>

@optional

/* Taken photo or video */
- (void)imagePickerController:(ImagePickerController *)picker
       didCreateMediaResource:(GenericMediaResource *)genericMediaItem
                      options:(NSDictionary<NSString *, id> *)options;

/* Choose assets from library */
- (void)imagePickerController:(ImagePickerController *)picker
        didPickMediaResources:(NSArray<GenericMediaResource *> *)genericMediaResources
                  withOptions:(NSDictionary<NSString *, id> *)options;

/* Cancel selection */
- (void)imagePickerController:(ImagePickerController *)picker
         didCancelWithOptions:(NSDictionary<NSString *, id> *)options;

@end


@interface ImagePickerController : NSObject

- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options;
- (void)present;

@property (weak, nonatomic) id<ImagePickerControllerDelegate> delegate;

@end

