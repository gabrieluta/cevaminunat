//
//  CameraPickerPhotoResizeHeaderView.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerPhotoResizeHeaderView.h"
#import "CameraPickerAppearance.h"
#import "CameraPickerResourceLoader.h"

#import "UIButton+CameraPicker.h"

#define PSA_PHOTO_RESIZE_HEADER_VIEW_DEFAULT_ANIMATION_DURATION 0.5f

@interface CameraPickerPhotoResizeHeaderView()

@property (nonatomic, weak) UIButton *photoSizeButton;
@property (nonatomic, weak) UIButton *originalSizeButton;
@property (nonatomic, weak) UIButton *mediumSizeButton;
@property (nonatomic, weak) UIButton *smallSizeButton;
@property (nonatomic, strong) NSLayoutConstraint *defaultHeightConstraint;

@end

@implementation CameraPickerPhotoResizeHeaderView

- (instancetype)init {
    self = [super init];
    if (self) {
        if (self.subviews.count == 0) {
            [self setupPhotoSizeHeaderView];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        if (self.subviews.count == 0) {
            [self setupPhotoSizeHeaderView];
        }
    }
    return self;
}

- (void)setPhotoSize:(CameraPickerPhotoSize)photoSize {
    
    _photoSize = photoSize;
    [self setPhotoSizeButtonImageForPhotoSize:photoSize];
}

- (void)activateDefaultHeightConstraint:(BOOL)active {
    self.defaultHeightConstraint.active = active;
}

#pragma mark - Actions

- (void)didTapButton:(UIButton *)button {
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:PSA_PHOTO_RESIZE_HEADER_VIEW_DEFAULT_ANIMATION_DURATION animations:^{
        
        if (button == weakSelf.photoSizeButton) {
            if (!weakSelf.isUnfolded) {
                [weakSelf unfoldOptionsAnimated:YES];
            } else {
                [weakSelf collapseOptionsAnimated:YES];
            }
        } else {
            
            /* selected an option -> collapse options */
            if (button == weakSelf.originalSizeButton) {
                weakSelf.photoSize = CameraPickerPhotoSizeOriginal;
            } else if (button == weakSelf.mediumSizeButton) {
                weakSelf.photoSize = CameraPickerPhotoSizeMedium;
            } else if (button == weakSelf.smallSizeButton) {
                weakSelf.photoSize = CameraPickerPhotoSizeSmall;
            }
            
            [weakSelf collapseOptionsAnimated:YES];
            [weakSelf highlightButtonForCurrentState];
        }
    }];
    
    if (button != self.photoSizeButton) {
        [self.delegate photoSizeHeaderView:self didChangePhotoSize:self.photoSize];
    }
}

#pragma mark - UI Helpers

- (void)setupPhotoSizeHeaderView {
    
    _photoSize = CameraPickerPhotoSizeOriginal;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *photoSizeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.photoSizeButton = photoSizeButton;
    self.photoSizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *originalSizeButton = [[UIButton alloc] init];
    self.originalSizeButton = originalSizeButton;
    self.originalSizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *mediumSizeButton = [[UIButton alloc] init];
    self.mediumSizeButton = mediumSizeButton;
    self.mediumSizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *smallSizeButton = [[UIButton alloc] init];
    self.smallSizeButton = smallSizeButton;
    self.smallSizeButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.spacing = [CameraPickerAppearance defaultSpacingBetweenItems];
    self.layoutDirection = CameraUnfoldableOptionsLayoutDirectionLeftToRight;
    
    [self addArrangedSubview:self.photoSizeButton];
    [self addArrangedSubview:self.originalSizeButton];
    [self addArrangedSubview:self.mediumSizeButton];
    [self addArrangedSubview:self.smallSizeButton];
    
    [self collapseOptionsAnimated:NO];
    [self setupOptionButtons];
}

- (void)setupOptionButtons {
    
    UIFont *textOptionsFont = [CameraPickerAppearance fontForFoldableViewTextOptions];
    
    [self.photoSizeButton camp_setupWithInfo:@{
                                                  @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                  @"target" : self,
                                                  @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                  }];
    [self setPhotoSizeButtonImageForPhotoSize:CameraPickerPhotoSizeOriginal];
    NSLayoutConstraint *photoSizeButtonHeight = [self.photoSizeButton.heightAnchor constraintEqualToAnchor:self.photoSizeButton.superview.heightAnchor];
    NSLayoutConstraint *photoSizeButtonWidth = [self.photoSizeButton.widthAnchor constraintEqualToAnchor:self.photoSizeButton.heightAnchor];
    
    [self.originalSizeButton camp_setupWithInfo:@{
                                                     @"title" : [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerPhotoSizeOriginal"],
                                                     @"font" : textOptionsFont,
                                                     @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                     @"target" : self,
                                                     @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                     }];
    NSLayoutConstraint *originalSizeButtonHeight = [self.originalSizeButton.heightAnchor constraintEqualToAnchor:self.originalSizeButton.superview.heightAnchor];
    
    [self.mediumSizeButton camp_setupWithInfo:@{
                                                   @"title" : [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerPhotoSizeMedium"],
                                                   @"font" : textOptionsFont,
                                                   @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                   @"target" : self,
                                                   @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                   }];
    NSLayoutConstraint *mediumSizeButtonHeight = [self.mediumSizeButton.heightAnchor constraintEqualToAnchor:self.mediumSizeButton.superview.heightAnchor];
    
    [self.smallSizeButton camp_setupWithInfo:@{
                                                  @"title" : [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerPhotoSizeSmall"],
                                                  @"font" : textOptionsFont,
                                                  @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                  @"target" : self,
                                                  @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                  }];
    
    NSLayoutConstraint *smallSizeButtonHeight = [self.smallSizeButton.heightAnchor constraintEqualToAnchor:self.smallSizeButton.superview.heightAnchor];
    
    [NSLayoutConstraint activateConstraints:@[
                                              photoSizeButtonHeight, photoSizeButtonWidth,
                                              originalSizeButtonHeight,
                                              mediumSizeButtonHeight,
                                              smallSizeButtonHeight
                                              ]];
    [self highlightButtonForCurrentState];
}

- (void)setPhotoSizeButtonImageForPhotoSize:(CameraPickerPhotoSize)photoSize {
    
    switch (photoSize) {
            
        case CameraPickerPhotoSizeOriginal:
            [self.photoSizeButton setImage:[CameraPickerResourceLoader imageNamed:@"originalPhotoSizeIcon"] forState:UIControlStateNormal];
            break;
            
        case CameraPickerPhotoSizeMedium:
            [self.photoSizeButton setImage:[CameraPickerResourceLoader imageNamed:@"mediumPhotoSizeIcon"] forState:UIControlStateNormal];
            break;
            
        case CameraPickerPhotoSizeSmall:
            [self.photoSizeButton setImage:[CameraPickerResourceLoader imageNamed:@"smallPhotoSizeIcon"] forState:UIControlStateNormal];
            break;
    }
}

- (void)highlightButtonForCurrentState {
    
    switch (self.photoSize) {
            
        case CameraPickerPhotoSizeOriginal:
            [CameraPickerAppearance unghighlightButton:self.mediumSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.smallSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.originalSizeButton withSemiTransparentRoundedCornersBackground:NO];
            break;
            
        case CameraPickerPhotoSizeMedium:
            [CameraPickerAppearance unghighlightButton:self.originalSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.smallSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.mediumSizeButton withSemiTransparentRoundedCornersBackground:NO];
            break;
            
        case CameraPickerPhotoSizeSmall:
            [CameraPickerAppearance unghighlightButton:self.originalSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.mediumSizeButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.smallSizeButton withSemiTransparentRoundedCornersBackground:NO];
            break;
    }
}

#pragma mark - Constraints

- (NSLayoutConstraint *)defaultHeightConstraint {
    
    if (!_defaultHeightConstraint) {
        _defaultHeightConstraint = [self.heightAnchor constraintEqualToConstant:[CameraPickerAppearance defaultHeightForHeaderView]];
    }
    return _defaultHeightConstraint;
}

@end

