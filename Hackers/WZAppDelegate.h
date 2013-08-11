//
//  WZAppDelegate.h
//  Hackers
//
//  Created by Weiran Zhang on 02/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JSSlidingViewController, WZSplitCascadeViewController;

@interface WZAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) WZSplitCascadeViewController *splitCascadeViewController;
@property (strong, nonatomic) UIViewController *viewController;
@property (readonly, nonatomic) JSSlidingViewController *phoneViewController;

@end
