//
//  KernelGenerator.m
//  test
//
//  Created by Gabriela Dobrovat on 04/05/2018.
//  Copyright © 2018 4psa. All rights reserved.
//

#import "KernelGenerator.h"

@import UIKit;

@implementation KernelGenerator

- (NSArray*)kernelWithLength:(NSUInteger)length orientation:(NSUInteger)orientation {
    
    double cosine = cos(orientation * M_PI/180);
    double sine = sin(orientation * M_PI/180);
    
    NSUInteger point1x = 0;
    NSUInteger point1y = 0;
    double point2x = point1x + length * cosine;
    double point2y = point1y + length * sine;
    
    NSUInteger transPoint1x = point1x + (length - length * cosine)/2;
    NSUInteger transPoint1y = point1y + (length - length * sine)/2;
    
    NSUInteger transPoint2x = point2x + (length - length * cosine)/2;
    NSUInteger transPoint2y = point2y + (length - length * sine)/2;

//    create kernel image
    CGRect rect = CGRectMake(0, 0, length, length);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    UIColor *color = [UIColor blackColor];
    CGContextSetFillColorWithColor(currentContext, [color CGColor]);
    CGContextFillRect(currentContext, rect);
    
    
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetGrayStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 1.0);
    
    
//    [[UIColor whiteColor] set];
    /* Set the width for the line */
    CGContextSetLineWidth(currentContext, 1.0);
    /* Start the line at this point */
    CGContextMoveToPoint(currentContext,transPoint1x, length - transPoint1y);
    /* And end it at this point */
    CGContextAddLineToPoint(currentContext,transPoint2x + 1, length - transPoint2y - 1);
    /* Use the context's current color to draw the line */
    CGContextStrokePath(currentContext);
    
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    CGImageRef imageRef = [image CGImage]; //get the CGImageRef from our UIImage named 'img'
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    unsigned char *pixels = malloc(height*width*4); //1d array with size for every pixel. Each pixel has the components: Red,Green,Blue,Alpha
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB(); //color space info which we need to create our drawing env
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, 4*width, colorSpaceRef, kCGImageAlphaPremultipliedLast); //our quartz2d drawing env
    CGColorSpaceRelease(colorSpaceRef); //release the color space info
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); //draws the image to our env
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:width*height];
    
    for (int y=0;y<height;++y){
        for (int x=0;x<width;++x){
            int idx = (width*y+x)*4; //the index of pixel(x,y) in the 1d array pixels
            
            //now that we have our index and array we can start manipulating the pixels!
            
            CGFloat red = (CGFloat)pixels[idx];
            CGFloat green = (CGFloat)pixels[idx+1];
            CGFloat blue = (CGFloat)pixels[idx+2];
            
            CGFloat pixel_value = 0;
            if (red == 63) {
                pixel_value = 0;
            } else if (red == 236) {
                pixel_value = 1/width;
            }
            NSNumber *num = [NSNumber numberWithFloat:pixel_value];
            [result addObject:num];
            
            //Please note that this assumes an image format with alpha stored in the least significant bit.
            //See kCGImageAlphaPremultipliedLast for more info.
            //Change if needed and also update bitmapInfo provided to CGBitmapContextCreate
        }
    }
    
    
    imageRef = CGBitmapContextCreateImage(context); //create a CGIMageRef from our pixeldata
    //release the drawing env and pixel data
    CGContextRelease(context);
    free(pixels);
    
    
    return nil;
}


@end
