//
//  CameraPickerFlashHeaderView.m
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerFlashHeaderView.h"
#import "CameraPickerAppearance.h"
#import "CameraPickerResourceLoader.h"

#import "UIButton+CameraPicker.h"

@interface CameraPickerFlashHeaderView()

@property (nonatomic, weak) UIButton *flashButton;
@property (nonatomic, weak) UIButton *autoFlashButton;
@property (nonatomic, weak) UIButton *onFlashButton;
@property (nonatomic, weak) UIButton *offFlashButton;
@property (nonatomic, strong) NSLayoutConstraint *defaultHeightConstraint;

@end

@implementation CameraPickerFlashHeaderView

- (instancetype)init {
    self = [super init];
    if (self) {
        if (self.subviews.count == 0) {
            [self setupFlashHeaderView];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        if (self.subviews.count == 0) {
            [self setupFlashHeaderView];
        }
    }
    return self;
}

- (void)setFlashMode:(CameraFlashMode)flashMode {
    _flashMode = flashMode;
    [self setFlashButtonImageForState:flashMode];
}

- (void)setAvailableFlashModes:(NSArray<NSNumber *> *)availableFlashModes {
    _availableFlashModes = availableFlashModes;
    [self setupUIForAvailableFlashModes:availableFlashModes];
}

- (void)activateDefaultHeightConstraint:(BOOL)active {
    self.defaultHeightConstraint.active = active;
}

- (void)setupFlashHeaderView {
    
    _flashMode = CameraFlashModeAuto;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton = flashButton;
    self.flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *autoFlashButton = [[UIButton alloc] init];
    self.autoFlashButton = autoFlashButton;
    self.autoFlashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *onFlashButton = [[UIButton alloc] init];
    self.onFlashButton = onFlashButton;
    self.onFlashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *offFlashButton = [[UIButton alloc] init];
    self.offFlashButton = offFlashButton;
    self.offFlashButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.spacing = [CameraPickerAppearance defaultSpacingBetweenItems];
    self.layoutDirection = CameraUnfoldableOptionsLayoutDirectionLeftToRight;
    
    [self addArrangedSubview:self.flashButton];
    [self addArrangedSubview:self.autoFlashButton];
    [self addArrangedSubview:self.onFlashButton];
    [self addArrangedSubview:self.offFlashButton];
    
    [self collapseOptionsAnimated:NO];
    [self setupOptionButtons];
    [self setupUIForAvailableFlashModes:self.availableFlashModes];
}

- (void)setFlashButtonImageForState:(CameraFlashMode)flashMode {
    
    switch (flashMode) {
            
        case CameraFlashModeAuto:
            [self.flashButton setImage:[CameraPickerResourceLoader imageNamed:@"flashAutoIcon"] forState:UIControlStateNormal];
            self.flashButton.tintColor = [CameraPickerAppearance colorForUnhighlightedImageButton];
            break;
            
        case CameraFlashModeOn:
            [self.flashButton setImage:[CameraPickerResourceLoader imageNamed:@"flashOnIcon"] forState:UIControlStateNormal];
            self.flashButton.tintColor = [CameraPickerAppearance colorForHighlightedImageButton];
            break;
            
        case CameraFlashModeOff:
            [self.flashButton setImage:[CameraPickerResourceLoader imageNamed:@"flashOffIcon"] forState:UIControlStateNormal];
            self.flashButton.tintColor = [CameraPickerAppearance colorForUnhighlightedImageButton];
            break;
            
    }
}

- (void)highlightButtonForCurrentState {
    
    switch (self.flashMode) {
            
        case CameraFlashModeAuto:
            [CameraPickerAppearance unghighlightButton:self.onFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.offFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.autoFlashButton withSemiTransparentRoundedCornersBackground:NO];
            break;
            
        case CameraFlashModeOn:
            [CameraPickerAppearance unghighlightButton:self.autoFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.offFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.onFlashButton withSemiTransparentRoundedCornersBackground:NO];
            break;
            
        case CameraFlashModeOff:
            [CameraPickerAppearance unghighlightButton:self.onFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance unghighlightButton:self.autoFlashButton makeBackgroundTransparent:NO];
            [CameraPickerAppearance highlightButton:self.offFlashButton withSemiTransparentRoundedCornersBackground:NO];
            break;
            
    }
}

- (void)setupOptionButtons {
    
    UIFont *textOptionsFont = [CameraPickerAppearance fontForFoldableViewTextOptions];
    
    [self.flashButton camp_setupWithInfo:@{
                                              @"normalImage" : [CameraPickerResourceLoader imageNamed:@"flashOnIcon"],
                                              @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                              @"target" : self,
                                              @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                              }];
    
    NSLayoutConstraint *flashButtonHeight = [self.flashButton.heightAnchor constraintEqualToAnchor:self.flashButton.superview.heightAnchor];
    NSLayoutConstraint *flashButtonWidth = [self.flashButton.widthAnchor constraintEqualToAnchor:self.flashButton.heightAnchor];
    
    [self.autoFlashButton camp_setupWithInfo:@{
                                                  @"title" : [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerFlashAuto"],
                                                  @"font" : textOptionsFont,
                                                  @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                  @"target" : self,
                                                  @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                  }];
    NSLayoutConstraint *autoFlashButtonHeight = [self.autoFlashButton.heightAnchor constraintEqualToAnchor:self.autoFlashButton.superview.heightAnchor];
    
    [self.onFlashButton camp_setupWithInfo:@{
                                                @"title" : [CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerFlashOn"],
                                                @"font" : textOptionsFont,
                                                @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                @"target" : self,
                                                @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                }];
    NSLayoutConstraint *onFlashButtonHeight = [self.onFlashButton.heightAnchor constraintEqualToAnchor:self.onFlashButton.superview.heightAnchor];
    
    [self.offFlashButton camp_setupWithInfo:@{
                                                 @"title" :[CameraPickerResourceLoader localizedStringWithName:@"lCameraPickerFlashOff"],
                                                 @"font" : textOptionsFont,
                                                 @"tintColor" : [CameraPickerAppearance colorForUnhighlightedImageButton],
                                                 @"target" : self,
                                                 @"action" : [NSValue valueWithPointer:@selector(didTapButton:)]
                                                 }];
    
    NSLayoutConstraint *offFlashButtonHeight = [self.offFlashButton.heightAnchor constraintEqualToAnchor:self.offFlashButton.superview.heightAnchor];
    
    [NSLayoutConstraint activateConstraints:@[flashButtonHeight, flashButtonWidth,
                                              autoFlashButtonHeight,
                                              onFlashButtonHeight,
                                              offFlashButtonHeight]];
    [self highlightButtonForCurrentState];
}

- (void)setupUIForAvailableFlashModes:(NSArray<NSNumber *> *)flashModes {
    
    self.autoFlashButton.enabled = [flashModes containsObject:@(CameraFlashModeAuto)];
    self.onFlashButton.enabled = [flashModes containsObject:@(CameraFlashModeOn)];
    self.offFlashButton.enabled = [flashModes containsObject:@(CameraFlashModeOff)];
}

- (NSLayoutConstraint *)defaultHeightConstraint {
    if (!_defaultHeightConstraint) {
        _defaultHeightConstraint = [self.heightAnchor constraintEqualToConstant:[CameraPickerAppearance defaultHeightForHeaderView]];
    }
    return _defaultHeightConstraint;
}

#pragma mark - Actions

- (void)didTapButton:(UIButton *)button {
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:[CameraPickerAppearance defaultAnimationDuration] animations:^{
        
        if (button == weakSelf.flashButton) {
            if (!weakSelf.isUnfolded) {
                [weakSelf unfoldOptionsAnimated:YES];
            } else {
                [weakSelf collapseOptionsAnimated:YES];
            }
        } else {
            
            /* selected an option -> collapse options */
            if (button == weakSelf.autoFlashButton) {
                weakSelf.flashMode = CameraFlashModeAuto;
            } else if (button == weakSelf.onFlashButton) {
                weakSelf.flashMode = CameraFlashModeOn;
            } else if (button == weakSelf.offFlashButton) {
                weakSelf.flashMode = CameraFlashModeOff;
            }
            
            [weakSelf collapseOptionsAnimated:YES];
            [weakSelf highlightButtonForCurrentState];
        }
    }];
    
    if (button != self.flashButton) {
        [self.delegate flashHeaderView:self didChangeFlashMode:self.flashMode];
    }
}

@end
