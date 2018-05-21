//
//  ImagePickerController.h
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;
@class ImagePickerController;

/* Image picker presenter options */
extern NSString * const kImagePickerSourceType;
extern NSString * const kImagePickerCameraCaptureMode;
extern NSString * const kImagePickerAllowsEditing;
extern NSString * const kImagePickerMediaTypes;

/* Returned media version */
extern NSString * const kImagePickerReturnedMediaVersion;

/* Appearance */
extern NSString * const kImagePickerHorizontalMargin;

@protocol ImagePickerControllerDelegate<NSObject>

@optional

/* Taken photo */
- (void)imagePickerController:(ImagePickerController *)picker
       didCreateImageResource:(UIImage *)imageResource
                      options:(NSDictionary<NSString *, id> *)options;

/* Choose assets from library */
- (void)imagePickerController:(ImagePickerController *)picker
         didPickImageResource:(NSArray<UIImage *> *)imageResource
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
