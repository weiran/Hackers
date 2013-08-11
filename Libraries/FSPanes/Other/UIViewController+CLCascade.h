//
//  UIViewController+CLCascade.h
//  Cascade
//
//  Created by Błażej Biesiada on 5/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLCascadeNavigationController;
@class CLSplitCascadeViewController;

@interface UIViewController (CLCascade)

@property(nonatomic, readonly, retain) CLSplitCascadeViewController *splitCascadeViewController;
@property(nonatomic, readonly, retain) CLCascadeNavigationController *cascadeNavigationController;

@end
