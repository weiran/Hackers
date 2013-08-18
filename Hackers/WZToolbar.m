//
//  WZToolbar.m
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WZToolbar.h"

@implementation WZToolbar

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setTheme];
}

- (void)setTheme {
//    self.layer.shadowColor = [[UIColor blackColor] CGColor];
//    self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
//    self.layer.shadowRadius = 2.0f;
//    self.layer.shadowOpacity = 1.0f;
}

- (void)drawRect:(CGRect)rect {
    //// Color Declarations
    UIColor* fillColor = [WZTheme navigationColor];
    
    //// Frames
    CGRect frame = self.bounds;
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(3, 3)];
    [rectanglePath closePath];
    [fillColor setFill];
    [rectanglePath fill];
    
    UIBezierPath *bottomBorderPath = [UIBezierPath bezierPath];
    [bottomBorderPath moveToPoint:CGPointMake(0, 0)];
    [bottomBorderPath addLineToPoint:CGPointMake(frame.size.width, 0)];
    [bottomBorderPath closePath];
    [[WZTheme separatorColor] setStroke];
    [bottomBorderPath stroke];

}

@end
