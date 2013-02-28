//
//  WZNavigationController.m
//  Hackers
//
//  Created by Weiran Zhang on 28/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationController.h"

@interface WZNavigationController ()

@end

@implementation WZNavigationController

#pragma mark - Rotation

- (NSUInteger)supportedInterfaceOrientations {
    if (_allowsRotation) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate {
    return _allowsRotation;
}

@end
