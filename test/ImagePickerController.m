//
//  ImagePickerController.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "ImagePickerController.h"
#import "CameraPickerViewController.h"
#import <QBImagePickerController/QBImagePickerController.h>

@import MobileCoreServices;

/* Image picker presenter options */
NSString * const kImagePickerSourceType = @"kImagePickerSourceType";
NSString * const kImagePickerCameraCaptureMode = @"kImagePickerCameraCaptureMode";
NSString * const kImagePickerAllowsEditing = @"kImagePickerAllowsEditing";
NSString * const kImagePickerMediaTypes = @"kImagePickerMediaTypes";
NSString * const kImagePickerSetupForAvatarSelection = @"kImagePickerSetupForAvatarSelection";

/* Returned media version */
NSString * const kImagePickerReturnedMediaVersion = @"kImagePickerReturnedMediaVersion";
/* Appearance */
NSString * const kImagePickerHorizontalMargin = @"kImagePickerHorizontalMargin";
/* Maximum number of selection */
NSString * const kImagePickerMaximumNumberOfSelection = @"kImagePickerMaximumNumberOfSelection";

@interface ImagePickerController ()<CameraPickerViewControllerDelegate,
                                    QBImagePickerControllerDelegate>

@property (nonatomic, strong) NSDictionary<NSString *, id> *options;
@property (nonatomic, weak) UIViewController *presentedPicker;
@property (nonatomic, strong) UIWindow *overlayWindow;

@property (nonatomic, strong) PSAMediaResourceFactory *mediaResourceFactory;

@end

@implementation PSAImagePickerController

- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options {
    
    self = [super init];
    
    if (self) {
        self.options = options;
    }
    
    return self;
}

#pragma mark - Getters

- (NSManagedObjectContext *)context {
    return [[PSADataModelManager sharedInstance] mainQueueManagedObjectContext];
}

- (PSAMediaResourceFactory *)mediaResourceFactory {
    
    if (_mediaResourceFactory) return _mediaResourceFactory;
    
    _mediaResourceFactory = [[PSAMediaResourceFactory alloc] initWithApplicationSettings:PSAAccount.sharedInstance.activeTeam.settings
                                                                    managedObjectContext:self.context];
    return _mediaResourceFactory;
}

- (NSUInteger)maximumNumberOfSelection {
    return [self.options objectForKey:kImagePickerMaximumNumberOfSelection] ? [[self.options objectForKey:kImagePickerMaximumNumberOfSelection] integerValue] : NSNotFound;
}

- (void)present {
    
    id pickerController;
    
    if ([self.options valueForKey:kImagePickerSourceType] &&
        [[self.options valueForKey:kImagePickerSourceType] integerValue] == UIImagePickerControllerSourceTypeCamera) {
        
        pickerController = [[PSANavigationAwareCameraPickerViewController alloc] init];
        PSANavigationAwareCameraPickerViewController *cameraPickerController = (PSANavigationAwareCameraPickerViewController *)pickerController;
        cameraPickerController.setupForAvatarSelection = [[self.options valueForKey:kImagePickerSetupForAvatarSelection] boolValue];
        cameraPickerController.delegate = self;
        
        if (self.maximumNumberOfSelection > 0) {
            
            if ([self.options valueForKey:kImagePickerMediaTypes]) {
                cameraPickerController.mediaTypes = [self.options objectForKey:kImagePickerMediaTypes];
            }
            
            cameraPickerController.allowsPhotoEditing = [[self.options objectForKey:kImagePickerAllowsEditing] boolValue];
            
        } else {
            [PSAFileAlerts showReachedUploadLimitAlertFromViewController:cameraPickerController
                                                           actionHandler:nil];
        }
        
    } else {
        
        pickerController = [[PSAPhotosLibraryPickerController alloc] init];
        PSAPhotosLibraryPickerController *qbImagePickerController = (PSAPhotosLibraryPickerController *)pickerController;
        qbImagePickerController.delegate = self;
        qbImagePickerController.horizontalMargin = [[self.options objectForKey:kImagePickerHorizontalMargin] doubleValue];
        qbImagePickerController.showsNumberOfSelectedAssets = YES;
        
        if ([self.options objectForKey:kImagePickerMaximumNumberOfSelection]) {
            
            qbImagePickerController.maximumNumberOfSelection = [[self.options objectForKey:kImagePickerMaximumNumberOfSelection] integerValue];
            
        } else {
            
            PSA_LOG(1, @"Please add a value for kImagePickerMaximumNumberOfSelection");
            qbImagePickerController.maximumNumberOfSelection = NSNotFound;
        }
        
        if ([self.options valueForKey:kImagePickerMediaTypes] &&
            ((NSArray *)[self.options valueForKey:kImagePickerMediaTypes]).count == 1) {
            
            NSArray *mediaTypes = (NSArray *)[self.options valueForKey:kImagePickerMediaTypes];
            
            if ([mediaTypes.firstObject isEqualToString:(NSString *)kUTTypeImage]) {
                
                qbImagePickerController.mediaType = QBImagePickerMediaTypeImage;
                
            } else if ([mediaTypes.firstObject isEqualToString:(NSString *)kUTTypeVideo] ||
                       [mediaTypes.firstObject isEqualToString:(NSString *)kUTTypeMovie]) {
                
                qbImagePickerController.mediaType = QBImagePickerMediaTypeVideo;
            }
            
        } else {
            
            qbImagePickerController.mediaType = QBImagePickerMediaTypeAny;
        }
        
        qbImagePickerController.allowsPhotoEditing = [[self.options objectForKey:kImagePickerAllowsEditing] boolValue];
        qbImagePickerController.setupForAvatarSelection = [[self.options valueForKey:kImagePickerSetupForAvatarSelection] boolValue];
    }
    
    [[[PSAInterfaceNavigator sharedInstance] topViewController] presentViewController:(UIViewController *)pickerController
                                                                             animated:YES
                                                                           completion:nil];
    self.presentedPicker = (UIViewController *)pickerController;
}

#pragma mark - CameraPickerViewControllerDelegate

- (void)cameraPickerController:(CameraPickerViewController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didCreateMediaResource:options:)]) {
        
        PSAGenericMediaResource *genericMediaResource;
        
        if ([info[kCameraPickerMediaType] isEqualToString:(__bridge NSString*)kUTTypeImage]) {
            
            NSData *imageData;
            
            switch ([[self.options objectForKey:kImagePickerReturnedMediaVersion] integerValue]) {
                    
                case PSAImagePickerReturnedMediaVersionCurrent:
                case PSAImagePickerReturnedMediaVersionOriginal:
                    imageData = [info objectForKey:kCameraPickerPickedImageData];
                    break;
                    
                default:
                    break;
            }
            
            if (imageData) {
                
                NSString *uniqueID = [PSAUtils generateUUID];
                genericMediaResource = [self.mediaResourceFactory cameraMediaResourceWithId:uniqueID
                                                                               imageContent:imageData
                                                                                   isEdited:[info[kCameraPickerMediaWasEdited] boolValue]];
            }
            
        } else if ([info[kCameraPickerMediaType] isEqualToString:(__bridge NSString*)kUTTypeVideo] ||
                   [info[kCameraPickerMediaType] isEqualToString:(__bridge NSString*)kUTTypeMovie]) {
            
            NSURL *assetURL = [info objectForKey:kCameraPickerMediaURL];
            if (assetURL) {
                genericMediaResource = [self.mediaResourceFactory videoMediaResourceWithLocalPath:assetURL.path];
            }
        }
        
        if (genericMediaResource) {
            
            __weak __typeof(self) weakSelf = self;
            [genericMediaResource loadContentWithCompletionHandler:^(NSData * _Nonnull data) {
                [weakSelf.delegate imagePickerController:weakSelf didCreateMediaResource:genericMediaResource options:weakSelf.options];
            }];
            
        }
    }
    
    [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)cameraPickerControllerDidCancel:(CameraPickerViewController *)picker {
    
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didCancelWithOptions:)]) {
        [self.delegate imagePickerController:self didCancelWithOptions:self.options];
    }
    
    [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (PSAImageEditorViewController *)newImageEditorForCameraPickerController:(CameraPickerViewController *)picker {
    PSANavigationAwareImageEditorViewController *imageEditor = [[PSANavigationAwareImageEditorViewController alloc] init];
    return imageEditor;
}

#pragma mark - QBImagePickerControllerDelegate

- (BOOL)qb_imagePickerController:(QBImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset {
    
    if (imagePickerController.maximumNumberOfSelection == 1) {
        return YES;
    }
    
    if (imagePickerController.selectedAssets.count < imagePickerController.maximumNumberOfSelection) {
        return YES;
    } else {
        [PSAFileAlerts showReachedUploadLimitAlertFromViewController:imagePickerController
                                                       actionHandler:nil];
        return NO;
    }
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController
          didFinishPickingAssets:(NSArray<PHAsset *> *)assets
containingEditedImagesDictionary:(NSDictionary<NSString *, NSData *> *)editedImagesData {
    
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didPickMediaResources:withOptions:)]) {
        
        NSMutableArray *genericMediaResourcesArray = [[NSMutableArray alloc] initWithCapacity:assets.count];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            /* Assets fetch operation is dispatched on global queue because we need to create a dispatch group that waits for all assets loading before delegate call, which can only be performed asynchronously. Since dispatch_group_wait blocks the thread it was entered on, this cannot be the main thread since callback for assets fetch is performed only on main thread by the api, so it would create a deadlock. Now fetch operation is ran on background queue, asset callback block responds on the main queue, and group leave is performed safely. */
            
            for (NSInteger assetIndex = 0; assetIndex < assets.count; assetIndex++) {
                
                PHAsset *asset = assets[assetIndex];
                __block PSAGenericMediaResource *photoLibaryMediaItem = nil;
                
                dispatch_group_t group = dispatch_group_create();
                dispatch_group_enter(group);
                
                if (asset.mediaType == PHAssetMediaTypeImage) {
                    
                    NSBlockOperation *blockOperation;
                    
                    NSData *editedImageData = [editedImagesData objectForKey:asset.localIdentifier];
                    if (editedImageData) {
                        
                        blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                            
                            photoLibaryMediaItem = [self.mediaResourceFactory photoLibraryMediaResourceWithAsset:asset
                                                                                                     editedImage:editedImageData];
                            dispatch_group_leave(group);
                        }];
                        
                    } else {
                        
                        PHImageRequestOptionsVersion photosAssetVersion;
                        
                        switch ([[self.options objectForKey:kImagePickerReturnedMediaVersion] integerValue]) {
                                
                            case PSAImagePickerReturnedMediaVersionCurrent:
                                photosAssetVersion = PHImageRequestOptionsVersionCurrent;
                                break;
                                
                            case PSAImagePickerReturnedMediaVersionOriginal:
                            default:
                                photosAssetVersion = PHImageRequestOptionsVersionOriginal;
                                break;
                        }
                        
                        blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                            
                            photoLibaryMediaItem = [self.mediaResourceFactory photoLibraryMediaResourceWithAsset:asset
                                                                                                    assetVersion:photosAssetVersion
                                                                                                 completionBlock:^(BOOL loaded) {
                                                                                                     dispatch_group_leave(group);
                                                                                                 }];
                        }];
                    }
                    
                    [[NSOperationQueue mainQueue] addOperations:@[ blockOperation ] waitUntilFinished:YES];
                    
                    
                } else if (asset.mediaType == PHAssetMediaTypeVideo) {
                    
                    PHVideoRequestOptionsVersion videoAssetVersion;
                    
                    switch ([[self.options objectForKey:kImagePickerReturnedMediaVersion] integerValue]) {
                            
                        case PSAImagePickerReturnedMediaVersionCurrent:
                            videoAssetVersion = PHVideoRequestOptionsVersionCurrent;
                            break;
                            
                        case PSAImagePickerReturnedMediaVersionOriginal:
                        default:
                            videoAssetVersion = PHVideoRequestOptionsVersionOriginal;
                            break;
                    }
                    
                    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                        
                        photoLibaryMediaItem = [self.mediaResourceFactory photoLibraryMediaResourceWithAsset:asset
                                                                                                assetVersion:videoAssetVersion
                                                                                             completionBlock:^(BOOL loaded) {
                                                                                                 dispatch_group_leave(group);
                                                                                             }];
                    }];
                    
                    [[NSOperationQueue mainQueue] addOperations:@[ blockOperation ] waitUntilFinished:YES];
                }
                
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [imagePickerController updateFetchedAssetsCount:assetIndex+1];
                });
                
                if (photoLibaryMediaItem) {
                    [genericMediaResourcesArray addObject:photoLibaryMediaItem];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                /* It is safer to always call image picker delegate on main queue since UI operations are usually performed there. */
                [self.delegate imagePickerController:self didPickMediaResources:genericMediaResourcesArray withOptions:self.options];
                
                [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
            });
        });
    }
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    
    if ([self.delegate respondsToSelector:@selector(imagePickerController:didCancelWithOptions:)]) {
        [self.delegate imagePickerController:self didCancelWithOptions:self.options];
    }
    
    [self.presentedPicker dismissViewControllerAnimated:YES completion:NULL];
}

- (PSAImageEditorViewController *)newImageEditorForQBImagePickerController:(QBImagePickerController *)imagePickerController {
    PSANavigationAwareImageEditorViewController *imageEditor = [[PSANavigationAwareImageEditorViewController alloc] init];
    return imageEditor;
}

@end

