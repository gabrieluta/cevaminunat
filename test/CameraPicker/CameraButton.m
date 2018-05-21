//
//  CameraButton.m
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraButton.h"
#import "UIImage+CameraPicker.h"

@implementation CameraButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupButtonStyle];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupButtonStyle];
    }
    return self;
}

- (void)setupButtonStyle {
    
    self.tintColor = [UIColor whiteColor];
    if (self.subviews.count == 0) {
        UIImageView *outerRingImageView = [[UIImageView alloc] initWithImage:[self outerRingImage]];
        [self insertSubview:outerRingImageView atIndex:0];
    }
    [self setImage:[self innerCircle] forState:UIControlStateNormal];

}

#pragma mark - Images

- (UIImage *)outerRingImage {
    
    UIImage *image = [UIImage camp_imageWithSize:CGSizeMake(66.0f, 66.0f) drawBlock:^(CGContextRef context, CGSize size) {
        UIBezierPath *outerRingPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(3, 3, 60, 60)];
        [self.tintColor setStroke];
        outerRingPath.lineWidth = 6;
        [outerRingPath stroke];
    }];
    return image;
}


- (UIImage *)innerCircle {
    
    UIImage *image = [UIImage camp_imageWithSize:CGSizeMake(66.0f, 66.0f) drawBlock:^(CGContextRef context, CGSize size) {
        UIBezierPath *innerCirclePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(8, 8, 50, 50)];
        [self.tintColor setFill];
        [innerCirclePath fill];
    }];
    return image;
}

- (UIImage *)innerSquare {
    
    UIImage *image = [UIImage camp_imageWithSize:CGSizeMake(66.0f, 66.0f) drawBlock:^(CGContextRef context, CGSize size) {
        
        CGFloat squareWidthHeight = 30.0f;
        UIBezierPath *innerSquare = [UIBezierPath bezierPathWithRect:CGRectMake(size.height / 2.0f - squareWidthHeight / 2.0f,
                                                                                size.width / 2.0f - squareWidthHeight / 2.0,
                                                                                squareWidthHeight,
                                                                                squareWidthHeight)];
        [self.tintColor setFill];
        [innerSquare fill];
    }];
    return image;
}


@end
