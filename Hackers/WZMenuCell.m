//
//  WZMenuCell.m
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZMenuCell.h"

@implementation WZMenuCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (selected) {
        self.textLabel.textColor = [UIColor blackColor];
    } else {
        self.textLabel.textColor = [WZTheme menuTitleColor];
    }
}

@end
