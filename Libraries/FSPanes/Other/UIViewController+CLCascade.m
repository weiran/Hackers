//
//  UIViewController+CLCascade.m
//  Cascade
//
//  Created by Błażej Biesiada on 5/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+CLCascade.h"
#import "FSPanes/CLSplitViewController/CLSplitCascadeViewController.h"
#import "FSPanes/CLCascadeNavigationController/CLCascadeNavigationController.h"

@implementation UIViewController (CLCascade)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CLSplitCascadeViewController *)splitCascadeViewController {
    UIViewController *parent = self.parentViewController;
    
    if ([parent isKindOfClass:[CLSplitCascadeViewController class]]) {
        return (CLSplitCascadeViewController *)parent;
    }
    else {
        return parent.splitCascadeViewController;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CLCascadeNavigationController *)cascadeNavigationController {
    UIViewController *parent = self.parentViewController;
    
    if ([parent isKindOfClass:[CLCascadeNavigationController class]]) {
        return (CLCascadeNavigationController *)parent;
    }
    else {
        return parent.cascadeNavigationController;
    }
}

@end
