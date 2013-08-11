//
//  CLBorderShadowView.m
//  Cascade
//
//  Created by Emil Wojtaszek on 23.08.2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CLBorderShadowView.h"

@implementation CLBorderShadowView

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) drawRect:(CGRect)rect {
    CGFloat colors [] = { 
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.3
    };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
        
    CGPoint startPoint = CGPointMake(0, CGRectGetMidY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient), gradient = NULL;
}

@end
