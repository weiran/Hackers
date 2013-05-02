//
//  WZButton.m
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZButton.h"

@implementation WZButton

- (void)awakeFromNib {
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.titleLabel.textColor = [UIColor colorWithRed:50.0/255.0 green:79.0/255.0 blue:133.0/255.0 alpha:1];
    self.titleLabel.font = [UIFont fontWithName:kBodyFontName size:kBodyFontSize];
}


- (void)drawRect:(CGRect)rect {
    if ([WZTheme lightTheme]) {
        [self drawLightTheme];
    } else {
        [self drawDarkTheme];
    }
}

- (void)drawDarkTheme {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* iconShadow = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* buttonColor = [UIColor colorWithRed: 0.616 green: 0.639 blue: 0.71 alpha: 1];
    CGFloat buttonColorRGBA[4];
    [buttonColor getRed: &buttonColorRGBA[0] green: &buttonColorRGBA[1] blue: &buttonColorRGBA[2] alpha: &buttonColorRGBA[3]];
    
    UIColor* baseGradientBottomColor = [UIColor colorWithRed: (buttonColorRGBA[0] * 0.6) green: (buttonColorRGBA[1] * 0.6) blue: (buttonColorRGBA[2] * 0.6) alpha: (buttonColorRGBA[3] * 0.6 + 0.4)];
    
    //// Gradient Declarations
    NSArray* baseGradientColors = [NSArray arrayWithObjects:
                                   (id)buttonColor.CGColor,
                                   (id)baseGradientBottomColor.CGColor, nil];
    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);
    
    //// Shadow Declarations
    UIColor* buttonShadow = iconShadow;
    CGSize buttonShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat buttonShadowBlurRadius = 2;
    
    //// Frames
    CGRect frame = self.bounds;
    
    //// Button
    {
        //// ButtonRectangle Drawing
        CGRect buttonRectangleRect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, CGRectGetHeight(frame) - 3);
        UIBezierPath* buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect: buttonRectangleRect cornerRadius: 3];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, buttonShadowOffset, buttonShadowBlurRadius, buttonShadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [buttonRectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient,
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMinY(buttonRectangleRect)),
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMaxY(buttonRectangleRect)),
                                    0);
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
        
    }
    
    
    //// Cleanup
    CGGradientRelease(baseGradient);
    CGColorSpaceRelease(colorSpace);
}

- (void)drawLightTheme {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* iconShadow = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.8];
    UIColor* buttonColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    CGFloat buttonColorRGBA[4];
    [buttonColor getRed: &buttonColorRGBA[0] green: &buttonColorRGBA[1] blue: &buttonColorRGBA[2] alpha: &buttonColorRGBA[3]];
    
    UIColor* baseGradientBottomColor = [UIColor colorWithRed: (buttonColorRGBA[0] * 0.8) green: (buttonColorRGBA[1] * 0.8) blue: (buttonColorRGBA[2] * 0.8) alpha: (buttonColorRGBA[3] * 0.8 + 0.2)];
    
    //// Gradient Declarations
    NSArray* baseGradientColors = [NSArray arrayWithObjects:
                                   (id)buttonColor.CGColor,
                                   (id)baseGradientBottomColor.CGColor, nil];
    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);
    
    //// Shadow Declarations
    UIColor* buttonShadow = iconShadow;
    CGSize buttonShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat buttonShadowBlurRadius = 2;
    
    //// Frames
    CGRect frame = self.bounds;
    
    //// Button
    {
        //// ButtonRectangle Drawing
        CGRect buttonRectangleRect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, CGRectGetHeight(frame) - 3);
        UIBezierPath* buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect: buttonRectangleRect cornerRadius: 3];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, buttonShadowOffset, buttonShadowBlurRadius, buttonShadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [buttonRectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient,
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMinY(buttonRectangleRect)),
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMaxY(buttonRectangleRect)),
                                    0);
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
        
    }
    
    
    //// Cleanup
    CGGradientRelease(baseGradient);
    CGColorSpaceRelease(colorSpace);
    

}

@end
