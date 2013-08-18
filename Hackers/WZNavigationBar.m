//
//  WZNavigationBar.m
//  Hackers
//
//  Created by Weiran Zhang on 03/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationBar.h"
#import <QuartzCore/QuartzCore.h>

@implementation WZNavigationBar

//- (void)awakeFromNib {
//    [self setTheme];    
//}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setTheme];
}

- (void)setTheme {
//    self.layer.shadowColor = [[UIColor blackColor] CGColor];
//    self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
//    self.layer.shadowRadius = 2.0f;
//    self.layer.shadowOpacity = 1.0f;
    
    self.titleTextAttributes = @{
        UITextAttributeFont : [UIFont fontWithName:kNavigationFontName size:kNavigationFontSize],
        UITextAttributeTextColor : [WZTheme titleTextColor],
        UITextAttributeTextShadowColor  : [UIColor clearColor]
    };
}

- (void)drawRect:(CGRect)rect {
    //// Color Declarations
    UIColor* fillColor = [WZTheme navigationColor];
    
    //// Frames
    CGRect frame = self.bounds;
    
    //// Rectangle Drawing
    UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(3, 3)];
    [rectanglePath closePath];
    [fillColor setFill];
    [rectanglePath fill];
    
    UIBezierPath *bottomBorderPath = [UIBezierPath bezierPath];
    [bottomBorderPath moveToPoint:CGPointMake(0, frame.size.height)];
    [bottomBorderPath addLineToPoint:CGPointMake(frame.size.width, frame.size.height)];
    [bottomBorderPath closePath];
    [[WZTheme separatorColor] setStroke];
    [bottomBorderPath stroke];
}

@end
