//
//  CameraPickerUnfoldableOptionsView.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CameraUnfoldableOptionsLayoutDirection) {
    CameraUnfoldableOptionsLayoutDirectionLeftToRight,
    CameraUnfoldableOptionsLayoutDirectionRightToLeft,
    CameraUnfoldableOptionsLayoutDirectionUpToDown,
    CameraUnfoldableOptionsLayoutDirectionDownToUp
};

@class CameraPickerUnfoldableOptionsView;
@protocol CameraPickerUnfoldableOptionsViewDelegate<NSObject>

@optional
- (void)unfoldableOptionsView:(CameraPickerUnfoldableOptionsView *)view willChangeOptionsDisplay:(BOOL)optionsAreUnfollded;
@end


@interface CameraPickerUnfoldableOptionsView : UIView

@property (nonatomic, assign, getter=isUnfolded) BOOL unfolded;
@property (nonatomic, weak) id<CameraPickerUnfoldableOptionsViewDelegate> foldingDelegate;
@property (nonatomic, assign) NSUInteger spacing;
@property (nonatomic, assign) CameraUnfoldableOptionsLayoutDirection layoutDirection;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSLayoutConstraint *> *customConstraints;

- (void)addArrangedSubview:(UIView *)view;
- (void)unfoldOptionsAnimated:(BOOL)animated;
- (void)collapseOptionsAnimated:(BOOL)animated;
- (void)prepareForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
