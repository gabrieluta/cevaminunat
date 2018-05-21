//
//  CameraPickerUnfoldableOptionsView.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerUnfoldableOptionsView.h"
#import "CameraPickerAppearance.h"

@interface CameraPickerUnfoldableOptionsView()

@end

@implementation CameraPickerUnfoldableOptionsView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.customConstraints = [[NSMutableDictionary alloc] init];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.customConstraints = [[NSMutableDictionary alloc] init];
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)addArrangedSubview:(UIView *)view {
    
    NSLayoutConstraint *viewConstraint;
    UIView *precedingView;
    
    if (self.subviews.count == 0) {
        
        // this is the first option
        precedingView = self;
        [self addSubview:view];
        
        switch (self.layoutDirection) {
                
            case CameraUnfoldableOptionsLayoutDirectionLeftToRight:
                viewConstraint = [view.leadingAnchor constraintEqualToAnchor:precedingView.leadingAnchor];
                [view.centerYAnchor constraintEqualToAnchor:precedingView.centerYAnchor].active = YES;
                break;
            case CameraUnfoldableOptionsLayoutDirectionRightToLeft:
                viewConstraint = [view.trailingAnchor constraintEqualToAnchor:precedingView.trailingAnchor];
                [view.centerYAnchor constraintEqualToAnchor:precedingView.centerYAnchor].active = YES;
                break;
            case CameraUnfoldableOptionsLayoutDirectionUpToDown:
                viewConstraint = [view.topAnchor constraintEqualToAnchor:precedingView.topAnchor];
                [view.centerXAnchor constraintEqualToAnchor:precedingView.centerXAnchor].active = YES;
                break;
            case CameraUnfoldableOptionsLayoutDirectionDownToUp:
                viewConstraint = [view.bottomAnchor constraintEqualToAnchor:precedingView.bottomAnchor];
                [view.centerXAnchor constraintEqualToAnchor:precedingView.centerXAnchor].active = YES;
                break;
        }
        
    } else {
        
        precedingView = [self.subviews lastObject];
        [self addSubview:view];
        
        switch (self.layoutDirection) {
                
            case CameraUnfoldableOptionsLayoutDirectionLeftToRight:
                viewConstraint = [view.leadingAnchor constraintEqualToAnchor:precedingView.trailingAnchor];
                [view.centerYAnchor constraintEqualToAnchor:precedingView.centerYAnchor].active = YES;
                viewConstraint.constant = self.spacing;
                break;
            case CameraUnfoldableOptionsLayoutDirectionRightToLeft:
                viewConstraint = [precedingView.leadingAnchor constraintEqualToAnchor:view.trailingAnchor];
                [view.centerYAnchor constraintEqualToAnchor:precedingView.centerYAnchor].active = YES;
                viewConstraint.constant = self.spacing;
                break;
            case CameraUnfoldableOptionsLayoutDirectionUpToDown:
                viewConstraint = [precedingView.bottomAnchor constraintEqualToAnchor:view.topAnchor];
                [view.centerXAnchor constraintEqualToAnchor:precedingView.centerXAnchor].active = YES;
                viewConstraint.constant = self.spacing;
                break;
            case CameraUnfoldableOptionsLayoutDirectionDownToUp:
                viewConstraint = [view.bottomAnchor constraintEqualToAnchor:precedingView.topAnchor];
                [view.centerXAnchor constraintEqualToAnchor:precedingView.centerXAnchor].active = YES;
                viewConstraint.constant = self.spacing;
                break;
        }
    }
    
    
    
    if (self.subviews.count != 1) {
        [self.customConstraints setObject:viewConstraint forKey:@([self.subviews indexOfObject:precedingView])];
    } else {
        [self.customConstraints setObject:viewConstraint forKey:@(-1)];
    }
    
    viewConstraint.active = YES;
}

- (void)unfoldOptionsAnimated:(BOOL)animated {
    
    void (^unfoldBlock)(void) = ^{
        for (UIView *subview in self.subviews) {
            subview.alpha = 1.0f;
        }
        self.backgroundColor = [CameraPickerAppearance colorForSemiTransparentViewBackground];
        self.unfolded = YES;
    };
    
    if ([self.foldingDelegate respondsToSelector:@selector(unfoldableOptionsView:willChangeOptionsDisplay:)]) {
        [self.foldingDelegate unfoldableOptionsView:self willChangeOptionsDisplay:YES];
    }
    if (animated) {
        [UIView animateWithDuration:[CameraPickerAppearance optionsFoldingAnimationDuration]
                         animations:unfoldBlock];
    } else {
        unfoldBlock();
    }
}

- (void)collapseOptionsAnimated:(BOOL)animated {
    
    void (^collapseBlock)(void) = ^{
        for (UIView *subview in self.subviews) {
            if (subview == self.subviews.firstObject) {
                continue;
            }
            subview.alpha = 0.0f;
        }
        self.backgroundColor = [CameraPickerAppearance colorForTransparentBackground];
        self.unfolded = NO;
    };
    
    if ([self.foldingDelegate respondsToSelector:@selector(unfoldableOptionsView:willChangeOptionsDisplay:)]) {
        [self.foldingDelegate unfoldableOptionsView:self willChangeOptionsDisplay:NO];
    }
    if (animated) {
        [UIView animateWithDuration:[CameraPickerAppearance optionsFoldingAnimationDuration]
                         animations:collapseBlock];
    } else {
        collapseBlock();
    }
}

- (void)prepareForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    UIView *firstView = self.subviews.firstObject;
    if (firstView) {
        
        firstView.transform = CGAffineTransformIdentity;
        
        switch (deviceOrientation) {
            case UIDeviceOrientationLandscapeLeft:
                firstView.transform = CGAffineTransformMakeRotation(M_PI_2);
                break;
            case UIDeviceOrientationLandscapeRight:
                firstView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                break;
            default:
                break;
        }
    }
}

@end
