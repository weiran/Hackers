//
//  WZWebView.m
//  Hackers
//
//  Created by Weiran Zhang on 03/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZWebView.h"

#import <QuartzCore/QuartzCore.h>

@implementation WZWebView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //self.backgroundColor = [UIColor colorWithWhite:0.84 alpha:1];
    self.backgroundColor = [UIColor underPageBackgroundColor];
    
//    for (UIView* subView in [self subviews]) {
//        if ([subView isKindOfClass:[UIScrollView class]]) {
//            for (UIView* shadowView in [subView subviews]) {
//                if ([shadowView isKindOfClass:[UIImageView class]]) {
//                    [shadowView setHidden:YES];
//                }
//            }
//        }
//    }

}

@end
