//
//  ViewController.m
//  test
//
//  Created by Gabriela Dobrovat on 15/03/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "ViewController.h"
#import "DeconvolutionFilter.h"
#import <Accelerate/Accelerate.h>

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
    self.image.image =  [UIImage imageNamed:@"blurredImage"];
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
    
//    If you plan to call this function multiple times
//    *  (rather than with iterationCount > 1) on 8-bit per channel images, you can save some computation by converting the 8-bit image data to
//    *  single precision floating-point yourself using something like vImageConvert_Planar8toPlanarF and iterating on the appropriate
//    *  floating-point Richardson Lucy variant. Convert back, when you are done.
    //perform convolution - this is the call for our type of data
    
    //Prepare data structures
//    int divisor = 9;
//    int iterationCount = 100;
    const float kernel[9] = {-1/8, -1/8, -1/8, -1/8, 1, -1/8, -1/8, -1/8, -1/8};
//    unsigned char bgColor[4] = { 0, 0, 0, 0 };
    Pixel_F backgroundColor = 0.5;

    error = vImageConvolve_PlanarF(&inBuffer,
                                   &outBuffer,
                                   nil,
                                   0,
                                   0,
                                   kernel,
                                   3,
                                   3,
                                   backgroundColor,
                                   kvImageCopyInPlace
                                   );
    
    //check for an error in the call to perform the convolution
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    //create CGImageRef from vImage_Buffer output
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             32,
                                             outBuffer.width * 4,
                                             colorSpace,
                                             (CGBitmapInfo)kCGImageAlphaNone|kCGBitmapFloatComponents);
    
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
