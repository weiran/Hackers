//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

//#import <SWRevealViewController/SWRevealViewController.h>
#import "WZMenuViewController.h"

//#import "WZMainViewController.h"
//#import "WZHackersData.h"

@implementation WZMenuViewController

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
////    UINavigationController *navigationController = segue.destinationViewController;
////    if ([segue.identifier isEqualToString:@"TopNewsSegue"]) {
////        WZMainViewController *mainViewController = navigationController.viewControllers[0];
////        mainViewController.newsType = WZNewsTypeTop;
////    } else if ([segue.identifier isEqualToString:@"NewNewsSegue"]) {
////        WZMainViewController *mainViewController = navigationController.viewControllers[0];
////        mainViewController.newsType = WZNewsTypeNew;
////    }
//    
//    if ([segue isKindOfClass:[SWRevealViewControllerSegue class]]) {
//        SWRevealViewControllerSegue *revealSegue = (SWRevealViewControllerSegue *)segue;
//        SWRevealViewController *revealViewController = self.revealViewController;
//        NSAssert( [revealViewController.frontViewController isKindOfClass:[UINavigationController class]], @"This segue will always want a UINavigationController in the front." );
//
//        [revealSegue setPerformBlock:^(SWRevealViewControllerSegue *revealViewControllerSegue, UIViewController *sourceViewController, UIViewController *destinationViewController) {
//            UINavigationController *navigationController = (UINavigationController *)revealViewController.frontViewController;
//            [navigationController setViewControllers:@[destinationViewController] animated:YES];
//            [revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
//        }];
//    }
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
}

@end
