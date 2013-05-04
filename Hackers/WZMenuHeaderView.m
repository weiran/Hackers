//
//  WZMenuTitleCell.m
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZMenuHeaderView.h"

@implementation WZMenuHeaderView

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* borderColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    UIColor* buttonColor = [UIColor colorWithRed: 0.267 green: 0.29 blue: 0.306 alpha: 1];
    UIColor* baseGradientBottomColor = [UIColor colorWithRed: 0.204 green: 0.224 blue: 0.239 alpha: 1];
    UIColor* iconShadow = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* color = [UIColor colorWithRed: 0.8 green: 0.8 blue: 0.8 alpha: 1];
    
    //// Gradient Declarations
    NSArray* baseGradientColors = [NSArray arrayWithObjects:
                                   (id)buttonColor.CGColor,
                                   (id)baseGradientBottomColor.CGColor, nil];
    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);
    
    //// Shadow Declarations
    UIColor* titleTextShadow = iconShadow;
    CGSize titleTextShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat titleTextShadowBlurRadius = 1;
    
    //// Frames
    CGRect frame = self.bounds;
    
    
    //// Group
    {
        //// Rectangle Drawing
        CGRect rectangleRect = CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: rectangleRect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(3, 3)];
        [rectanglePath closePath];
        CGContextSaveGState(context);
        [rectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient,
                                    CGPointMake(CGRectGetMidX(rectangleRect), CGRectGetMinY(rectangleRect)),
                                    CGPointMake(CGRectGetMidX(rectangleRect), CGRectGetMaxY(rectangleRect)),
                                    0);
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, titleTextShadowOffset, titleTextShadowBlurRadius, titleTextShadow.CGColor);
        [color setFill];
        [@"Hackers" drawInRect: CGRectInset(rectangleRect, 10, 6) withFont: [UIFont fontWithName: @"HelveticaNeue-Medium" size: 16] lineBreakMode: NSLineBreakByWordWrapping alignment: NSTextAlignmentLeft];
        CGContextRestoreGState(context);
        
        
        
        //// Border Bottom Drawing
        UIBezierPath* borderBottomPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + CGRectGetHeight(frame) - 1, CGRectGetWidth(frame), 1)];
        [borderColor setFill];
        [borderBottomPath fill];
    }
    
    
    //// Cleanup
    CGGradientRelease(baseGradient);
    CGColorSpaceRelease(colorSpace);
    
}

@end
