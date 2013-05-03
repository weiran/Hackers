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

- (id)init {
    self = [super init];
    if (!self) return nil;
    [self setLayerShadow];
    return self;
}

- (void)awakeFromNib {
    [self setLayerShadow];    
}

- (void)setLayerShadow {
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0.0f, -1.0f);
    self.layer.shadowRadius = 2.0f;
    self.layer.shadowOpacity = 1.0f;
}

- (void)drawRect:(CGRect)rect {
    if ([WZTheme lightTheme]) {
        [self drawLightThemeRect];
    } else {
        [self drawDarkThemeRect];
    }
}

- (void)drawLightThemeRect {
    //// Color Declarations
    UIColor* fillColor = [UIColor colorWithRed: 0.949 green: 0.949 blue: 0.949 alpha: 1];
    
    //// Frames
    CGRect frame = self.bounds;
    
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(3, 3)];
    [rectanglePath closePath];
    [fillColor setFill];
    [rectanglePath fill];
}

- (void)drawDarkThemeRect {
    //// Color Declarations
    UIColor* color = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.665];
    
    //// Frames
    CGRect frame = self.bounds;
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(3, 3)];
    [rectanglePath closePath];
    [color setFill];
    [rectanglePath fill];
}

@end
