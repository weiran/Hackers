//
//  WZPostCell.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WZPostCell.h"

@implementation WZPostCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.backgroundView) {
        UIImage *backgroundImage = [[UIImage imageNamed:@"cell-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 0, 0, 0)];
        self.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        self.backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        self.layer.sublayers = nil;
        
        UIColor *gradientStartColor = [UIColor colorWithRed:202/255 green:209/255 blue:223/255 alpha:1];
        UIColor *gradientEndColor = [UIColor colorWithRed:179/255 green:188/255 blue:203/255 alpha:1];
        
        self.backgroundView = nil;
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = @[gradientStartColor, gradientEndColor];
        [self.layer insertSublayer:gradient atIndex:0];
    }
}

@end
