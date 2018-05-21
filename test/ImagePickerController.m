//
//  ImagePickerController.m
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "ImagePickerController.h"

#import <QBImagePickerController/QBImagePickerController.h>
//TODO: Implement CameraPickerViewControllerDelegate methods
@interface ImagePickerController ()<QBImagePickerControllerDelegate>

@property (nonatomic, strong) NSDictionary<NSString *, id> *options;
@property (nonatomic, weak) UIViewController *presentedPicker;
@property (nonatomic, strong) UIWindow *overlayWindow;

//@property (nonatomic, strong) PSAMediaResourceFactory *mediaResourceFactory;

@end

@implementation ImagePickerController

#pragma mark - QBImagePickerControllerDelegate

- (BOOL)qb_imagePickerController:(QBImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset {
    
    if (imagePickerController.maximumNumberOfSelection == 1) {
        return YES;
    }
    return NO;
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        /* It is safer to always call image picker delegate on main queue since UI operations are usually performed there. */
        [self.delegate imagePickerController:self didPickImageResource:assets withOptions:self.options];
        
        [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
    });
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didCancelWithOptions:)]) {
        [self.delegate imagePickerController:self didCancelWithOptions:self.options];
    }
    
    [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
}

@end
