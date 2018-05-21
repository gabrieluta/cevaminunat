//
//  CameraPickerResourceLoader.h
//  test
//
//  Created by Gabriela Dobrovat on 21/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface CameraPickerResourceLoader : NSObject

+ (NSString *)localizedStringWithName:(NSString *)name;
+ (UIImage *)imageNamed:(NSString*)imageName;
+ (NSBundle *)resourceBundle;

@end
