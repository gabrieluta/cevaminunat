//
//  DeconvolutionFilter.m
//  test
//
//  Created by Gabriela Dobrovat on 21/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "DeconvolutionFilter.h"
#import "DeconvolutionFilterConstructor.h"

@implementation DeconvolutionFilter

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            if ([CIFilter respondsToSelector:@selector(registerFilterName:constructor:classAttributes:)]) {
                [CIFilter registerFilterName:NSStringFromClass([self class])
                                 constructor:(id)self
                             classAttributes:@{kCIAttributeFilterCategories: @[
                                                       kCICategoryColorAdjustment, kCICategoryVideo,
                                                       kCICategoryStillImage, kCICategoryInterlaced,
                                                       kCICategoryNonSquarePixels],
                                               kCIAttributeFilterDisplayName: @"DeconvolutionFilter"}];
            }
        }
    });
}

+ (CIFilter *)filterWithName:(NSString *)name {
    return [[NSClassFromString(name) alloc] init];
}

static CIKernel *testKernel = nil;

- (id)init {
    
    self = [super init];
    
    if (testKernel == nil) {
        
        NSBundle *bundle = [NSBundle bundleForClass: [self class]];
        NSURL *kernelURL = [bundle URLForResource:@"testkernel" withExtension:@"cikernel"];
        NSError *error;
        NSString *kernelCode = [NSString stringWithContentsOfURL:kernelURL encoding:NSUTF8StringEncoding error:&error];
        
        if (kernelCode == nil) {
            NSLog(@"Error loading kernel code string in %@\n%@", NSStringFromSelector(_cmd), [error localizedDescription]);
            abort();
        }
        
        NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
        testKernel = [kernels objectAtIndex:0];
    }
    
    return self;
}

//- (NSDictionary *)customAttributes
//{
//    srcImage = [NSNumber numberWithInt:5];
//    return @{
//             @"numSamples": numSamples,
//             kCIAttributeFilterName : @"BlurFilter"
//             };
//}

- (CIImage *)outputImage {
    
    if (!self.inputImage) {
        return nil;
    }
    
    return [testKernel applyWithExtent:self.inputImage.extent
                           roiCallback:^CGRect(int index, CGRect destRect) {
                               // what is this?
                               return CGRectZero;
                           } arguments:@[self.inputImage.imageByClampingToExtent]];
}

@end
