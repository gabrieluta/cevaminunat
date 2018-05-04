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
    
    [[UIColor whiteColor] set];
    /* Set the width for the line */
    CGContextSetLineWidth(currentContext,1.0f);
    /* Start the line at this point */
    CGContextMoveToPoint(currentContext,transPoint1x, transPoint1y);
    /* And end it at this point */
    CGContextAddLineToPoint(currentContext,transPoint2x, transPoint2y);
    /* Use the context's current color to draw the line */
    CGContextStrokePath(currentContext);
    
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
//    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    
    return nil;
}


@end
