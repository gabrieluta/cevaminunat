//
//  CameraButton.h
//  test
//
//  Created by Gabriela Dobrovat on 18/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CameraButtonStyle) {
    CameraButtonStylePhotoCapture,
    CameraButtonStyleUnknown = NSNotFound
};

IB_DESIGNABLE
@interface CameraButton : UIButton

@property (nonatomic, assign) CameraButtonStyle style;

@end
