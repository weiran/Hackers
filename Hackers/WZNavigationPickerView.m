//
//  WZNavigationPickerView.m
//  Hackers
//
//  Created by Weiran Zhang on 30/01/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationPickerView.h"
#import <QuartzCore/QuartzCore.h>

@implementation WZNavigationPickerView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.67 alpha:1];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // Create the path (with only the top-left corner rounded)
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                   byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight
                                                         cornerRadii:CGSizeMake(2.5, 2.5)];
    
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the image view's layer
    self.layer.mask = maskLayer;

}

@end
