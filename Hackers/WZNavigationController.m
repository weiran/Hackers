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

- (void)setNewsType:(WZNewsType)newsType {
    WZMainViewController *mainViewController = self.viewControllers[0];
    mainViewController.newsType = newsType;
}

//- (UILabel *)titleLabel {
//    return (UILabel *)self.navigationItem.titleView;
//}
//
//- (void)setTitle:(NSString *)title {
//    [super setTitle:title];
//    UILabel *titleView = [self titleLabel];
//    
//    if (!titleView) {
//        UILabel *label = [[UILabel alloc] init];
//        label.backgroundColor = [UIColor clearColor];
//        label.font = [UIFont fontWithName:kNavigationFontName size:kNavigationFontSize];
//        label.textColor = [WZTheme titleTextColor];
//        label.textAlignment = NSTextAlignmentCenter;
//        [label sizeToFit];
//        
//        self.navigationItem.titleView = label;
//    }
//    
//    titleView.text = title;
//    [titleView sizeToFit];
//}

@end
