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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    double duration = 0;
    
    if (animated) {
        duration = 0.2;
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
        if (selected) {
            self.backgroundColor = [UIColor colorWithWhite:0.87 alpha:1];
        } else {
            self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        }
    }];
}

@end
