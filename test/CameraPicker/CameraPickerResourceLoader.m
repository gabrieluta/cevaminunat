//
//  CameraPickerResourceLoader.m
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "CameraPickerResourceLoader.h"

@import UIKit;

@implementation CameraPickerResourceLoader

+ (NSString *)localizedStringWithName:(NSString *)name {
    
    NSString *localizedString = NSLocalizedStringFromTableInBundle(name,
                                                                   @"CameraPickerLocalizable",
                                                                   [CameraPickerResourceLoader resourceBundle],
                                                                   nil);
    
    return localizedString;
}

+ (UIImage *)imageNamed:(NSString*)imageName {
    
    UIImage *image = [UIImage imageNamed:imageName inBundle:[CameraPickerResourceLoader resourceBundle] compatibleWithTraitCollection:nil];
    if (!image) {
        image = [UIImage imageNamed:imageName];
    }
    return image;
}

+ (NSBundle *)resourceBundle {
    return [NSBundle bundleForClass:[self class]];
}

@end
