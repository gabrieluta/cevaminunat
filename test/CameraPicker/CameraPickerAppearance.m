//
//  CameraPickerAppearance.m
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerAppearance.h"

@implementation CameraPickerAppearance

#pragma mark - Colors

+ (UIColor *)colorForHighlightedTextOptions {
    return UIColorFromHex(0xFFBF00);
}

+ (UIColor *)colorForUnhightlightedTextOptions {
    return [UIColor whiteColor];
}

+ (UIColor *)colorForHighlightedImageButton {
    return UIColorFromHex(0xFFBF00);
}

+ (UIColor *)colorForUnhighlightedImageButton {
    return [UIColor whiteColor];
}

+ (UIColor *)colorForSemiTransparentButtonBackground {
    return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
}

+ (UIColor *)colorForSemiTransparentViewBackground {
    return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.4f];
}

+ (UIColor *)colorForTransparentBackground {
    return [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
}

+ (UIColor *)colorForPhotoPreviewBackground {
    return [UIColor blackColor];
}

+ (UIColor *)colorForUnavailableCameraLabelText {
    return [UIColor whiteColor];
}

#pragma mark - Distances

+ (CGFloat)defaultHorizontalMargin {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 20.0f;
    }
    return 10.0f;
}

+ (CGFloat)horizontalMarginForButtonWithSize:(CGSize)buttonSize imageSize:(CGSize)imageSize {
    return MAX(0.0f, [CameraPickerAppearance defaultHorizontalMargin] - ((buttonSize.width - imageSize.width) / 2.0f));
}

+ (CGFloat)defaultVerticalMargin {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 20.0f;
    }
    return 10.0f;
}

+ (CGFloat)defaultSpacingBetweenItems {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 20.0f;
    }
    return 10.0f;
}

#pragma mark - Sizes

+ (CGSize)defaultButtonSize {
    return CGSizeMake(44.0f, 44.0f);
}

+ (CGSize)defaultSizeForHeaderButton {
    return CGSizeMake([CameraPickerAppearance defaultHeightForHeaderView],
                      [CameraPickerAppearance defaultHeightForHeaderView]);
}

+ (CGFloat)defaultHeightForHeaderView {
    return 50.0f;
}

#pragma mark - Fonts

+ (UIFont *)fontForFoldableViewTextOptions {
    return [UIFont systemFontOfSize:14.0f];
}

#pragma mark - Timing Info

+ (NSTimeInterval)defaultAnimationDuration {
    return 0.5f;
}

+ (NSTimeInterval)defaultPresentationDuration {
    return 0.5f;
}

+ (NSTimeInterval)defaultDismissalDuration {
    return 0.25f;
}

+ (NSTimeInterval)cameraSwitchAnimationDuration {
    return 0.5f;
}

+ (NSTimeInterval)captureModeChangeAnimatioDuration {
    return 1.0f;
}

+ (NSTimeInterval)captureModeHighlightAnimationDuration {
    return 0.5f;
}

+ (NSTimeInterval)optionsFoldingAnimationDuration {
    return 0.5f;
}

+ (NSTimeInterval)photoChangeAnimationDuration {
    return 0.5f;
}

#pragma mark - Button appearance

+ (void)highlightButton:(UIButton *)button withSemiTransparentRoundedCornersBackground:(BOOL)addSemiTransparentRoundedCornersBackground {
    
    [button setTitleColor:[CameraPickerAppearance colorForHighlightedTextOptions] forState:UIControlStateNormal];
    
    if (addSemiTransparentRoundedCornersBackground) {
        button.layer.cornerRadius = button.frame.size.height / 2.0;
        button.clipsToBounds = YES;
        button.backgroundColor = [CameraPickerAppearance colorForSemiTransparentButtonBackground];
    }
}

+ (void)unghighlightButton:(UIButton *)button makeBackgroundTransparent:(BOOL)makeBackgroundTransparent {
    
    [button setTitleColor:[CameraPickerAppearance colorForUnhightlightedTextOptions] forState:UIControlStateNormal];
    if (makeBackgroundTransparent) {
        button.backgroundColor = [CameraPickerAppearance colorForTransparentBackground];
    }
}

@end
