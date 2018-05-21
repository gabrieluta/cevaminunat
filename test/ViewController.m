//
//  ViewController.m
//  test
//
//  Created by Gabriela Dobrovat on 15/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "ViewController.h"
#import <Accelerate/Accelerate.h>
#import "KernelGenerator.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapDeblurButton)];
    [self.button setUserInteractionEnabled:YES];
    [self.button addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.image.image =  [UIImage imageNamed:@"img"];
    self.image.contentMode = UIViewContentModeScaleToFill;
}

- (void)didTapDeblurButton {
    //[self drawRect:self.image.frame];
    self.image.image = [self boxblurImage:self.image.image boxSize:3];
}

- (void)drawRect:(CGRect)rect {
    
    CIContext* context = [CIContext context];
    if (context != nil) {
    
        CIFilter *filter = [CIFilter filterWithName: @"DeconvolutionFilter"
                                withInputParameters:@{
                                                      kCIInputImageKey:[[CIImage alloc] initWithImage:self.image.image],
                                                      }];

        CIImage *image = [filter valueForKey:@"outputImage"];
        self.image.image = [self cgBackedImageFromCIImage:image];
    }
}

- (UIImage *)cgBackedImageFromCIImage:(CIImage *)ciImage {
    
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(NO)}];
    if (!context) {
        context = [CIContext context];
    }
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *result = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return result;
}

-(UIImage *)boxblurImage:(UIImage *)image boxSize:(int)boxSize {
    //Get CGImage from UIImage
    CGImageRef img = image.CGImage;
    
    //setup variables
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    //create vImage_Buffer with data from CGImageRef
    
    //These two lines get get the data from the CGImage
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    //The next three lines set up the inBuffer object based on the attributes of the CGImage
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    //This sets the pointer to the data for the inBuffer object
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    
    //allocate a buffer for the output image and check if it exists in the next three lines
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    //set up the output buffer object based on the same dimensions as the input image
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    //Prepare data structures
//    int divisor = 9;
//    int iterationCount = 100;
    int16_t kernel[9] = {0, 0, 1, 0, 1, 0, 1, 0, 0};
//    unsigned char bgColor[4] = { 0, 0, 0, 0 };
//    Pixel_F backgroundColor = 0.5;
//    KernelGenerator *kernelGenerator = [[KernelGenerator alloc] init];
//    [kernelGenerator kernelWithLength:11 orientation:60];
    error = vImageRichardsonLucyDeConvolve_ARGB8888(&inBuffer,
                                                    &outBuffer,
                                                    nil,
                                                    0,
                                                    0,
                                                    kernel,
                                                    nil,
                                                    3,
                                                    3,
                                                    0,
                                                    0,
                                                    3,
                                                    0,
                                                    nil,
                                                    10,
                                                    kvImageCopyInPlace);
    
    //check for an error in the call to perform the convolution
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    //create CGImageRef from vImage_Buffer output
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end
