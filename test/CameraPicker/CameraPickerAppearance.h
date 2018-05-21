//
//  CameraPickerAppearance.h
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import Foundation;
@import UIKit;

#define UIColorFromHex(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromHexWithAlpha(rgbValue, alpha) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alpha]

@interface CameraPickerAppearance : NSObject

#pragma mark - Colors
+ (UIColor *)colorForHighlightedTextOptions;
+ (UIColor *)colorForUnhightlightedTextOptions;
+ (UIColor *)colorForHighlightedImageButton;
+ (UIColor *)colorForUnhighlightedImageButton;
+ (UIColor *)colorForSemiTransparentButtonBackground;
+ (UIColor *)colorForSemiTransparentViewBackground;
+ (UIColor *)colorForTransparentBackground;
+ (UIColor *)colorForPhotoPreviewBackground;
+ (UIColor *)colorForUnavailableCameraLabelText;

#pragma mark - Distances
+ (CGFloat)defaultHorizontalMargin;
+ (CGFloat)defaultVerticalMargin;
+ (CGFloat)defaultSpacingBetweenItems;
+ (CGFloat)horizontalMarginForButtonWithSize:(CGSize)buttonSize imageSize:(CGSize)imageSize;

#pragma mark - Sizes
+ (CGSize)defaultButtonSize;
+ (CGSize)defaultSizeForHeaderButton;
+ (CGFloat)defaultHeightForHeaderView;

#pragma mark - Fonts
+ (UIFont *)fontForFoldableViewTextOptions;

#pragma mark - Timing Info
+ (NSTimeInterval)defaultAnimationDuration;
+ (NSTimeInterval)defaultPresentationDuration;
+ (NSTimeInterval)defaultDismissalDuration;
+ (NSTimeInterval)cameraSwitchAnimationDuration;
+ (NSTimeInterval)captureModeChangeAnimatioDuration;
+ (NSTimeInterval)captureModeHighlightAnimationDuration;
+ (NSTimeInterval)optionsFoldingAnimationDuration;
+ (NSTimeInterval)photoChangeAnimationDuration;

+ (void)highlightButton:(UIButton *)button withSemiTransparentRoundedCornersBackground:(BOOL)addSemiTransparentRoundedCornersBackground;
+ (void)unghighlightButton:(UIButton *)button makeBackgroundTransparent:(BOOL)makeBackgroundTransparent;

@end

