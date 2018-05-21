//
//  UIButton+CameraPicker.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "UIButton+CameraPicker.h"

@implementation UIButton (CameraPicker)

- (void)psacamp_setupWithInfo:(NSDictionary *)info {
    
    NSString *title = info[@"title"];
    if (title) {
        [self setTitle:title forState:UIControlStateNormal];
    }
    UIImage *normalImage = info[@"normalImage"];
    if (normalImage) {
        [self setImage:normalImage forState:UIControlStateNormal];
    }
    UIColor *tintColor = info[@"tintColor"];
    if (self.tintColor) {
        self.tintColor = tintColor;
    }
    UIView *superview = info[@"superview"];
    [superview addSubview:self];
    UIColor *backgroundColor = info[@"backgroundColor"];
    if (backgroundColor) {
        self.backgroundColor = backgroundColor;
    }
    UIFont *font = info[@"font"];
    if (font) {
        self.titleLabel.font = font;
    }
    NSObject *target = info[@"target"];
    SEL action = [info[@"action"] pointerValue];
    if (target && action) {
        [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

@end
