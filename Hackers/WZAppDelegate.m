//
//  WZAppDelegate.m
//  Hackers
//
//  Created by Weiran Zhang on 02/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//


#import "WZAppDelegate.h"

#import "WZNavigationController.h"
#import "WZMenuViewController.h"
#import "WZTheme.h"
#import "WZSplitCascadeViewController.h"

#import <GCOLaunchImageTransition/GCOLaunchImageTransition.h>
#import "JSSlidingViewController.h"
#import "TSTapstream.h"
#import "Cascade.h"

@interface WZAppDelegate()
@property (readwrite, nonatomic) JSSlidingViewController *phoneViewController;
@end

@implementation WZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [WZTheme defaults];
    
    // initilise storyboard with JSSlidingViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard;
    
    if (IS_IPAD()) {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_ipad" bundle:nil];
        CLCascadeNavigationController *navController = [[CLCascadeNavigationController alloc] init];
        CLCategoriesViewController *menuViewController = [storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        
        self.splitCascadeViewController = [[WZSplitCascadeViewController alloc] initWithNavigationController:navController];
        self.splitCascadeViewController.categoriesViewController = menuViewController;
        
        self.window.rootViewController = self.splitCascadeViewController;
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        WZMenuViewController *menuController = [storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        self.viewController = [[JSSlidingViewController alloc] initWithFrontViewController:menuController.mainNavViewController backViewController:menuController];
        self.phoneViewController.useBouncyAnimations = NO;
        self.window.rootViewController = self.viewController;
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [GCOLaunchImageTransition transitionWithDuration:0.3 style:GCOLaunchImageTransitionAnimationStyleFade];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Saves changes in the application's managed object context before the application terminates.
}


- (JSSlidingViewController *)phoneViewController {
    return (JSSlidingViewController *)self.viewController;
}

@end
