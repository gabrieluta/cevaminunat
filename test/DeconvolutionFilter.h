//
//  DeconvolutionFilter.h
//  test
//
//  Created by Gabriela Dobrovat on 21/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface DeconvolutionFilter : CIFilter

{
    CIImage   *srcImage;
}

@property (nonatomic, strong) CIImage *inputImage;

@end
