//
//  CameraPickerPhotoResizeHeaderView.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerUnfoldableOptionsView.h"
#import "CameraPickerOverlayView.h"

@import UIKit;
typedef NS_ENUM(NSInteger, CameraPickerPhotoSize);

@class CameraPickerPhotoResizeHeaderView;
@protocol CameraPickerPhotoResizeHeaderViewDelegate <NSObject>

- (void)photoSizeHeaderView:(CameraPickerPhotoResizeHeaderView *)flashHeaderView didChangePhotoSize:(CameraPickerPhotoSize)photoSize;

@end

@interface CameraPickerPhotoResizeHeaderView : CameraPickerUnfoldableOptionsView

@property (nonatomic, assign) CameraPickerPhotoSize photoSize;
@property (nonatomic, weak) id<CameraPickerPhotoResizeHeaderViewDelegate> delegate;

- (void)activateDefaultHeightConstraint:(BOOL)active;
@end
