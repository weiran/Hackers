//
//  CLCascadeNavigationController.h
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSPanes/CLCascadeNavigationController/CLCascadeView.h"
#import "FSPanes/Other/CLGlobal.h"

@interface CLCascadeNavigationController : UIViewController <CLCascadeViewDataSource, CLCascadeViewDelegate> {
    // view containing all views on stack
    CLCascadeView* _cascadeView;
}


/*
 * Left inset of normal size pages from left boarder
 */
@property(nonatomic) CGFloat leftInset;

/*
 * Left inset of wider size page from left boarder. Default 220.0f
 */
@property(nonatomic) CGFloat widerLeftInset;

/*
 * Set and push root view controller
 */
- (void) setRootViewController:(UIViewController*)viewController animated:(BOOL)animated;
- (void) setRootViewController:(UIViewController*)viewController animated:(BOOL)animated viewSize:(CLViewSize)viewSize;

/*
 * Push new view controller from sender.
 * If sender is not last, then controller pop next controller and push new view from sender
 */
- (void) addViewController:(UIViewController*)viewController sender:(UIViewController*)sender animated:(BOOL)animated;
- (void) addViewController:(UIViewController*)viewController sender:(UIViewController*)sender animated:(BOOL)animated viewSize:(CLViewSize)size;

/* 
 First in hierarchy CascadeViewController (opposite to lastCascadeViewController)
 */
- (UIViewController*) rootViewController;

/* 
 Last in hierarchy CascadeViewController (opposite to rootViewController)
 */
- (UIViewController*) lastCascadeViewController;

/* 
 Return first visible view controller (load if needed)
 */
- (UIViewController*) firstVisibleViewController;


@end
