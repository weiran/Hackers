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
    [self setTheme];
}

- (void)setTheme {
    _titleLabel.textColor = [WZTheme titleTextColor];
    if (self.selected) {
        self.backgroundColor = [WZTheme highlightedBackgroundColor];
    } else {
        self.backgroundColor = [WZTheme backgroundColor];
    }
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
                             self.backgroundColor = [WZTheme highlightedBackgroundColor];
                         } else {
                             self.backgroundColor = [WZTheme backgroundColor];
                         }
                     }];
}

@end
