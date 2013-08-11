//
//  CLCascadeNavigationController.m
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CLCascadeNavigationController.h"
#import "FSPanes/Other/UIViewController+CLSegmentedView.h"
#import "FSPanes/Other/UIViewController+CLCascade.h"
#import "CLSegmentedView.h"

@interface CLCascadeNavigationController (Private)
- (void) addPagesRoundedCorners;
- (void) addRoundedCorner:(UIRectCorner)rectCorner toPageAtIndex:(NSInteger)index;
- (void) popPagesFromLastIndexTo:(NSInteger)index;
- (void) removeAllPageViewControllers;
@end

@implementation CLCascadeNavigationController

@synthesize leftInset, widerLeftInset;

- (void)dealloc
{
    _cascadeView = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // unload all invisible pages in cascadeView
    [_cascadeView unloadInvisiblePages];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // set background color
    [self.view setBackgroundColor: [UIColor clearColor]];

    _cascadeView = [[CLCascadeView alloc] initWithFrame:self.view.bounds];
    _cascadeView.delegate = self;
    _cascadeView.dataSource = self;
    [self.view addSubview:_cascadeView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_cascadeView removeFromSuperview];
    _cascadeView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:( UIInterfaceOrientation )interfaceOrientation
                                         duration:( NSTimeInterval )duration {
    [_cascadeView updateContentLayoutToInterfaceOrientation:interfaceOrientation
                                                   duration:duration ];
}


#pragma mark -
#pragma mark Setters & getters

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat) widerLeftInset {
    return _cascadeView.widerLeftInset;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setWiderLeftInset:(CGFloat)inset {
    [_cascadeView setWiderLeftInset: inset];    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat) leftInset {
    return _cascadeView.leftInset;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setLeftInset:(CGFloat)inset {
    [_cascadeView setLeftInset: inset];
}


#pragma mark -
#pragma marl test

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*) rootViewController {
    if ([self.childViewControllers count] > 0) {
        return [self.childViewControllers objectAtIndex: 0];
    }
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*) lastCascadeViewController {
    return [self.childViewControllers lastObject];
}


#pragma mark -
#pragma marl CLCascadeViewDataSource

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) cascadeView:(CLCascadeView *)cascadeView pageAtIndex:(NSInteger)index {
    return [[self.childViewControllers objectAtIndex:index] view];    
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) numberOfPagesInCascadeView:(CLCascadeView*)cascadeView {
    return [self.childViewControllers count];
}


#pragma mark -
#pragma marl CLCascadeViewDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView didLoadPage:(UIView*)page {

}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView didUnloadPage:(UIView*)page {

}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView didAddPage:(UIView*)page animated:(BOOL)animated {

}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView didPopPageAtIndex:(NSInteger)index {

}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView pageDidAppearAtIndex:(NSInteger)index {
    if (index > [self.childViewControllers count] - 1) return;

//TODO: Decide whether we want to send -viewDidAppear: here or not
//    UIViewController<CLViewControllerDelegate>* controller = [_viewControllers objectAtIndex: index];
//    if ([controller respondsToSelector:@selector(pageDidAppear)]) {
//        [controller pageDidAppear];
//    }
    
    [self addPagesRoundedCorners];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeView:(CLCascadeView*)cascadeView pageDidDisappearAtIndex:(NSInteger)index {
    if (index > [self.childViewControllers count] - 1) return;

//TODO: Decide whether we want to send -viewDidDisappear: here or not
//    UIViewController<CLViewControllerDelegate>* controller = [_viewControllers objectAtIndex: index];
//    if ([controller respondsToSelector:@selector(pageDidDisappear)]) {
//        [controller pageDidDisappear];
//    }

    [self addPagesRoundedCorners];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeViewDidStartPullingToDetachPages:(CLCascadeView*)cascadeView {
    /*
     Override this methods to implement own actions, animations
     */
    
    NSLog(@"cascadeViewDidStartPullingToDetachPages");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeViewDidPullToDetachPages:(CLCascadeView*)cascadeView {
    /*
     Override this methods to implement own actions, animations
     */
    NSLog(@"cascadeViewDidPullToDetachPages");

    // pop page from back
    [self popPagesFromLastIndexTo:0];
    //load first page
    [cascadeView loadPageAtIndex:0];
    
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cascadeViewDidCancelPullToDetachPages:(CLCascadeView*)cascadeView {
    /*
     Override this methods to implement own actions, animations
     */
    NSLog(@"cascadeViewDidCancelPullToDetachPages");
}

#pragma mark -
#pragma mark Calss methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setRootViewController:(UIViewController*)viewController animated:(BOOL)animated {
    [self setRootViewController:viewController animated:animated viewSize:CLViewSizeNormal];
}

- (void) setRootViewController:(UIViewController*)viewController animated:(BOOL)animated viewSize:(CLViewSize)viewSize
{
    // pop all pages
    [_cascadeView popAllPagesAnimated: NO];
    // remove all controllers
    [self removeAllPageViewControllers];
    // add root view controller
    [self addViewController:viewController sender:nil animated:animated viewSize:viewSize];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) addViewController:(UIViewController*)viewController sender:(UIViewController*)sender animated:(BOOL)animated {
    [self addViewController:viewController sender:sender animated:animated viewSize:CLViewSizeNormal];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) addViewController:(UIViewController*)viewController sender:(UIViewController*)sender animated:(BOOL)animated viewSize:(CLViewSize)size {
    // if in not sent from categoirs view
    if (sender) {
        
        // get index of sender
        NSInteger indexOfSender = [self.childViewControllers indexOfObject:sender];
        
        // if sender is not last view controller
        if (indexOfSender != [self.childViewControllers count] - 1) {
            
            // pop views and remove from _viewControllers
            [self popPagesFromLastIndexTo:indexOfSender];
        }
    }
    
    [self addChildViewController:viewController];
    
    // push view
    [_cascadeView pushPage:[viewController view] 
                  fromPage:[sender view] 
                  animated:animated
                  viewSize:size];
    
    [viewController didMoveToParentViewController:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIViewController*) firstVisibleViewController {
    NSInteger index = [_cascadeView indexOfFirstVisibleView: YES];

    if (index != NSNotFound) {
        return [self.childViewControllers objectAtIndex: index];
    }
    
    return nil;
}


#pragma mark -
#pragma mark Private

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) addRoundedCorner:(UIRectCorner)rectCorner toPageAtIndex:(NSInteger)index {

    if (index != NSNotFound) {
        UIViewController* firstVisibleController = [self.childViewControllers objectAtIndex: index];
        
        CLSegmentedView* view = firstVisibleController.segmentedView;
        [view setShowRoundedCorners: YES];
        [view setRectCorner: rectCorner];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) addPagesRoundedCorners {
    
    // unload all rounded corners
    for (id item in [_cascadeView visiblePages]) {
        if (item != [NSNull null]) {
            if ([item isKindOfClass:[CLSegmentedView class]]) {
                CLSegmentedView* view = (CLSegmentedView*)item;
                [view setShowRoundedCorners: NO];
            }
        }
    }

    // get index of first visible page
    NSInteger indexOfFirstVisiblePage = [_cascadeView indexOfFirstVisibleView: NO];
    
    // get index of last visible page
    NSInteger indexOfLastVisiblePage = [_cascadeView indexOfLastVisibleView: NO];

    if (indexOfLastVisiblePage == indexOfFirstVisiblePage) {
        [self addRoundedCorner:UIRectCornerAllCorners toPageAtIndex: indexOfFirstVisiblePage];
        
    } else {

        [self addRoundedCorner:UIRectCornerTopLeft | UIRectCornerBottomLeft toPageAtIndex:indexOfFirstVisiblePage];
        
        if (indexOfLastVisiblePage == [self.childViewControllers count] -1) {
            [self addRoundedCorner:UIRectCornerTopRight | UIRectCornerBottomRight toPageAtIndex:indexOfLastVisiblePage];
        }    
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) popPagesFromLastIndexTo:(NSInteger)toIndex {
    NSUInteger count = [self.childViewControllers count];

    if (count == 0) {
        return;
    }
        
    if (toIndex < 0) toIndex = 0;
    
    // index of last page
    NSUInteger index = count - 1;
    // pop page from back
    NSEnumerator* enumerator = [self.childViewControllers reverseObjectEnumerator];
    // enumarate pages
    while ([enumerator nextObject] && self.childViewControllers.count > toIndex+1) {
        if (![_cascadeView canPopPageAtIndex: index]) {
            //dodikk - maybe break fits better
            continue;
        }
        
        UIViewController* viewController = [self.childViewControllers objectAtIndex:index];
        [viewController willMoveToParentViewController:nil];

        // pop page at index
        [_cascadeView popPageAtIndex:index animated:NO];

        [viewController removeFromParentViewController];
        
        index--;
    }
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) removeAllPageViewControllers {

    // pop page from back
    NSEnumerator* enumerator = [self.childViewControllers reverseObjectEnumerator];
    // enumarate pages
    while ([enumerator nextObject]) {
        
        UIViewController* viewController = [self.childViewControllers lastObject];
        [viewController willMoveToParentViewController:nil];
        
        [viewController removeFromParentViewController];
    }
}

@end
