//
//  CameraPickerFlashHeaderView.h
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CameraPickerUnfoldableOptionsView.h"

typedef NS_ENUM(NSInteger, CameraFlashMode) {
    CameraFlashModeOff  = 0,
    CameraFlashModeOn   = 1,
    CameraFlashModeAuto = 2
};

@class CameraPickerFlashHeaderView;

@protocol CameraPickerFlashHeaderViewDelegate <NSObject>

- (void)flashHeaderView:(CameraPickerFlashHeaderView *)flashHeaderView didChangeFlashMode:(CameraFlashMode)flashMode;

@end

@interface CameraPickerFlashHeaderView : CameraPickerUnfoldableOptionsView

@property (nonatomic, weak) id<CameraPickerFlashHeaderViewDelegate> delegate;
@property (nonatomic, assign) CameraFlashMode flashMode;
@property (nonatomic, strong) NSArray <NSNumber *> *availableFlashModes;

- (void)activateDefaultHeightConstraint:(BOOL)active;

@end
