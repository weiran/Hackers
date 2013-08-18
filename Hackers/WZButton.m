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
    [self setTitleColor:[WZTheme titleTextColor] forState:UIControlStateNormal];
    [self setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
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
    UIColor* baseGradientBottomColor = [UIColor colorWithRed: 0.122 green: 0.122 blue: 0.122 alpha: 1];
    UIColor* buttonColor = [UIColor colorWithRed: 0.184 green: 0.184 blue: 0.184 alpha: 1];
    
    //// Gradient Declarations
    NSArray* baseGradientColors = [NSArray arrayWithObjects:
                                   (id)buttonColor.CGColor,
                                   (id)baseGradientBottomColor.CGColor, nil];
    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);
    CGColorSpaceRelease(colorSpace);

    //// Frames
    CGRect frame = self.bounds;
    
    
    //// Button
    {
        //// ButtonRectangle Drawing
        CGRect buttonRectangleRect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, CGRectGetHeight(frame) - 3);
        UIBezierPath* buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect: buttonRectangleRect cornerRadius: 3];
        CGContextSaveGState(context);
        CGContextBeginTransparencyLayer(context, NULL);
        [buttonRectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient,
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMinY(buttonRectangleRect)),
                                    CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMaxY(buttonRectangleRect)),
                                    0);
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
        CGGradientRelease(baseGradient);
    }
}

- (void)drawLightTheme {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* baseGradientBottomColor = [UIColor colorWithRed: 0.945 green: 0.945 blue: 0.945 alpha: 1];
    UIColor* buttonColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* iconShadow = [UIColor colorWithRed: 0.2 green: 0.2 blue: 0.2 alpha: 1];
    
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
