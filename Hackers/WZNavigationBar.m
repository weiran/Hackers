//
//  WZNavigationBar.m
//  Hackers
//
//  Created by Weiran Zhang on 27/01/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationBar.h"
#import "WZNavigationPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation WZNavigationBar

- (void)setBackgroundImage:(UIImage *)backgroundImage forBarMetrics:(UIBarMetrics)barMetrics {
    CATransition *transition = [CATransition new];
    transition.type = kCATransitionFade;
    transition.duration = 0.2;
    [self.layer addAnimation:transition forKey:@"contents"];
    
    [super setBackgroundImage:backgroundImage forBarMetrics:barMetrics];
}

@end;