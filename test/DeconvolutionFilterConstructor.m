//
//  DeconvolutionFilterConstructor.m
//  test
//
//  Created by Gabriela Dobrovat on 21/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "DeconvolutionFilterConstructor.h"

@implementation DeconvolutionFilterConstructor

- (CIFilter *)filterWithName:(NSString *)name {
    return [[NSClassFromString(name) alloc] init];
}

@end
