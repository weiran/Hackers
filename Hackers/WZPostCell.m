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
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self updateBackgroundColorHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self updateBackgroundColorHighlighted:selected animated:animated];
}

- (void)updateBackgroundColorHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    double duration = 0;
    
    if (animated) {
        duration = 0.2;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         if (highlighted) {
                             self.backgroundColor = [UIColor colorWithWhite:0.87 alpha:1];
                         } else {
                             self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
                         }
                     }];
}

@end
