//
//  JSSlidingViewController.m
//  JSSlidingViewControllerSample
//
//  Created by Jared Sinclair on 6/19/12.
//  Copyright (c) 2013 Jared Sinclair. All rights reserved.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// License Agreement for Source Code provided by Jared Sinclair
//
// This software is supplied to you by Jared Sinclair in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of this software constitutes acceptance
// of these terms. If you do not agree with these terms, please do not use, install, modify or redistribute
// this software.
//
// In consideration of your agreement to abide by the following terms, and subject to these terms, Jared
// Sinclair grants you a personal, non-exclusive license, to use, reproduce, modify and redistribute the software,
// with or without modifications, in source and/or binary forms; provided that if you redistribute the software in
// its entirety and without modifications, you must retain this notice and the following text and disclaimers in
// all such redistributions of the software, and that in all cases attribution of Jared Sinclair as the original
// author of the source code shall be included in all such resulting software products or distributions. Neither
// the name, trademarks, service marks or logos of Jared Sinclair may be used to endorse or promote products
// derived from the software without specific prior written permission from Jared Sinclair. Except as expressly
// stated in this notice, no other rights or licenses, express or implied, are granted by Jared Sinclair herein,
// including but not limited to any patent rights that may be infringed by your derivative works or by other works
// in which the software may be incorporated.
//
// The software is provided by Jared Sinclair on an "AS IS" basis. JARED SINCLAIR MAKES NO WARRANTIES, EXPRESS OR
// IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
// IN NO EVENT SHALL JARED SINCLAIR BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF JARED
// SINCLAIR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//

#import "JSSlidingViewController.h"

NSString *  const JSSlidingViewControllerWillOpenNotification               = @"JSSlidingViewControllerWillOpenNotification";
NSString *  const JSSlidingViewControllerWillCloseNotification              = @"JSSlidingViewControllerWillCloseNotification";
NSString *  const JSSlidingViewControllerDidOpenNotification                = @"JSSlidingViewControllerDidOpenNotification";
NSString *  const JSSlidingViewControllerDidCloseNotification               = @"JSSlidingViewControllerDidCloseNotification";
NSString *  const JSSlidingViewControllerWillBeginDraggingNotification      = @"JSSlidingViewControllerWillBeginDraggingNotification";
CGFloat     const JSSlidingViewControllerDefaultVisibleFrontPortionWhenOpen = 58.0f;
CGFloat     const JSSlidingViewControllerDropShadowImageWidth               = 20.0f;

@implementation SlidingScrollView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO; // So that dropshadow along the sides of the frontViewController still appear when the slider is open.
        self.backgroundColor = [UIColor clearColor];
        self.pagingEnabled = YES;
        self.bounces = NO;
        self.scrollsToTop = NO;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.delaysContentTouches = NO;
        self.canCancelContentTouches = YES;
    }
    return self;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    return YES; // Makes it so you can swipe to close the slider.
}

@end

@interface JSSlidingViewController () <UIScrollViewDelegate>

@property (nonatomic, assign)               CGFloat                 sliderOpeningWidth;
@property (nonatomic, assign)               CGFloat                 desiredVisiblePortionOfFrontViewWhenOpen;
@property (nonatomic, strong)               UIButton *              invisibleCloseSliderButton;
@property (nonatomic, strong)               UIImageView *           frontViewControllerDropShadow;
@property (nonatomic, strong)               UIImageView *           frontViewControllerDropShadow_right;
@property (nonatomic, assign)               BOOL                    isAnimatingInterfaceOrientation;
@property (nonatomic, assign, readwrite)    BOOL                    animating;
@property (nonatomic, assign, readwrite)    BOOL                    isOpen;
@property (nonatomic, strong, readwrite)    UIViewController *      frontViewController;
@property (nonatomic, strong, readwrite)    UIViewController *      backViewController;
@property (nonatomic, strong, readwrite)    SlidingScrollView *     slidingScrollView;

@end

@implementation JSSlidingViewController

#pragma mark - View Lifecycle

- (id)initWithFrontViewController:(UIViewController *)frontVC backViewController:(UIViewController *)backVC {
    NSAssert(frontVC, @"JSSlidingViewController requires both a front and a back view controller");
    NSAssert(backVC, @"JSSlidingViewController requires both a front and a back view controller");
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _frontViewController = frontVC;
        _backViewController = backVC;
        _useBouncyAnimations = YES;
        [self addObservations];
    }
    return self;
}

- (void)dealloc {
    [self removeObservations];
}

- (void)addObservations {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarFrameWillChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)removeObservations {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSlidingScrollView];
    CGRect frame = self.view.bounds;
    
    self.backViewController.view.frame = frame;
    self.backViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addChildViewController:self.backViewController];
    [self.view insertSubview:self.backViewController.view atIndex:0];
    [self.backViewController didMoveToParentViewController:self];
    
    self.frontViewController.view.frame = CGRectMake(_sliderOpeningWidth, frame.origin.y, frame.size.width, frame.size.height);
    [self addChildViewController:self.frontViewController];
    [_slidingScrollView addSubview:self.frontViewController.view];
    [self.frontViewController didMoveToParentViewController:self];
    
    [self didClose]; // Fixes VO bugs with the slider being closed at launch.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateInterface];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateInterface];
}

#pragma mark - Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL shouldAutorotate = NO;
    if ([self.delegate respondsToSelector:@selector(slidingViewController:shouldAutorotateToInterfaceOrientation:)]) {
        shouldAutorotate = [self.delegate slidingViewController:self shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    } else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            shouldAutorotate = (interfaceOrientation == UIInterfaceOrientationPortrait);
        } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            shouldAutorotate = YES;
        }
    }
    return shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations {
    NSUInteger interfaceOrientations = 0;
    if ([self.delegate respondsToSelector:@selector(supportedInterfaceOrientationsForSlidingViewController:)]) {
        interfaceOrientations = [self.delegate supportedInterfaceOrientationsForSlidingViewController:self];
    } else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            interfaceOrientations = UIInterfaceOrientationMaskPortrait;
        } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            interfaceOrientations = UIInterfaceOrientationMaskAll;
        }
    }
    return interfaceOrientations;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.isAnimatingInterfaceOrientation = YES;
    __weak JSSlidingViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        weakSelf.isAnimatingInterfaceOrientation = NO;
    });
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self updateInterface];
}

- (void)updateInterface {
    _sliderOpeningWidth = self.view.bounds.size.width - self.desiredVisiblePortionOfFrontViewWhenOpen;
    CGRect frame = self.view.bounds;
    CGFloat targetOriginForSlidingScrollView = 0;
    if (self.isOpen) {
        targetOriginForSlidingScrollView = _sliderOpeningWidth;
    }
    self.slidingScrollView.contentSize = CGSizeMake(frame.size.width + _sliderOpeningWidth, frame.size.height);
    self.frontViewControllerDropShadow.frame = CGRectMake(_sliderOpeningWidth - JSSlidingViewControllerDropShadowImageWidth, 0.0f, JSSlidingViewControllerDropShadowImageWidth, frame.size.height);
    self.frontViewControllerDropShadow_right.frame = CGRectMake(_sliderOpeningWidth + frame.size.width, 0.0f, JSSlidingViewControllerDropShadowImageWidth, frame.size.height);
    _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
    _slidingScrollView.frame = CGRectMake(targetOriginForSlidingScrollView, 0, frame.size.width, frame.size.height);
    self.frontViewController.view.frame = CGRectMake(_sliderOpeningWidth, 0, frame.size.width, frame.size.height);
    self.invisibleCloseSliderButton.frame = CGRectMake(_sliderOpeningWidth, self.invisibleCloseSliderButton.frame.origin.y, _desiredVisiblePortionOfFrontViewWhenOpen, frame.size.height);
    
    if (self.backViewController.view.superview == nil) {
        // Update this manually, since auto-resizing won't take care of it,
        // because it's been temporarily removed from the view hierarchy
        CGRect backvcframe = self.backViewController.view.frame;
        backvcframe = self.view.bounds;
        self.backViewController.view.frame = backvcframe;
    }
}

#pragma mark - Status Bar Changes

- (void)statusBarFrameWillChange:(NSNotification *)notification {
    NSDictionary *dictionary = notification.userInfo;
    
    CGRect targetStatusBarFrame = CGRectZero;
    NSValue *rectValue = [dictionary valueForKey:UIApplicationStatusBarFrameUserInfoKey];
    [rectValue getValue:&targetStatusBarFrame];
    
    CGRect screenbounds = [[UIScreen mainScreen] bounds];
    CGFloat targetHeight = screenbounds.size.height - targetStatusBarFrame.size.height;
    
    [UIView animateWithDuration:0.25f animations:^{
        [self updateContentSizeForViewHeight:targetHeight];
    }];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self updateContentSizeForViewHeight:self.view.bounds.size.height];
}

- (void)updateContentSizeForViewHeight:(CGFloat)targetHeight {
    
    // Adjust the content size for the sliding scroll to the new target height
    self.slidingScrollView.contentSize = CGSizeMake(self.slidingScrollView.contentSize.width, targetHeight);
    
    // Manually fix the back vc's height if the view isn't visible.
    // If it's visible, auto-resizing will correct it.
    if (self.backViewController.view.superview == nil) {
        CGRect backvcframe = self.backViewController.view.frame;
        backvcframe.size.height = targetHeight;
        self.backViewController.view.frame = backvcframe;
    }
    
    // Don't fix front vc. It'll get adjusted as the scroll view's content size changes,
    // as long as it has the right autoresizing mask (flexible height).
    
    // Fix dropshadows (helps with translucent status bar apps).
    CGRect shadowFrame = self.frontViewControllerDropShadow.frame;
    shadowFrame.size.height = targetHeight;
    self.frontViewControllerDropShadow.frame = shadowFrame;
    shadowFrame = self.frontViewControllerDropShadow_right.frame;
    shadowFrame.size.height = targetHeight;
    self.frontViewControllerDropShadow_right.frame = shadowFrame;
}

#pragma mark - Controlling the Slider

- (void)closeSlider:(BOOL)animated completion:(void (^)(void))completion {
    [completion copy];
    if (_animating == NO && _isOpen && _locked == NO) {
        [self willClose];
        _isOpen = NO; // Needs to be here to prevent bugs
        _animating = YES;
        if (self.useBouncyAnimations) {
            [self closeWithBouncyAnimation:animated completion:completion];
        } else {
            [self closeWithSmoothAnimation:animated completion:completion];
        }
    } else {
        if (completion) {
            completion();
        }
    }
}

- (void)closeWithBouncyAnimation:(BOOL)animated completion:(void(^)(void))completion {
    CGFloat duration1 = 0.0f;
    CGFloat duration2 = 0.0f;
    if (animated) {
        duration1 = 0.18f;
        duration2 = 0.1f;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            duration1 = duration1 * 1.5f;
            duration2 = duration2 * 1.5f;
        }
    }
    [UIView animateWithDuration: duration1 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration animations:^{
        CGRect rect = _slidingScrollView.frame;
        rect.origin.x = -10.0f;
        _slidingScrollView.frame = rect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration: duration2 delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration animations:^{
            CGRect rect = _slidingScrollView.frame;
            rect.origin.x = 0;
            _slidingScrollView.frame = rect;
        } completion:^(BOOL finished2) {
            if (self.invisibleCloseSliderButton) {
                [self.invisibleCloseSliderButton removeFromSuperview];
                self.invisibleCloseSliderButton = nil;
            }
            _animating = NO;
            self.view.userInteractionEnabled = YES;
            [self didClose];
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)closeWithSmoothAnimation:(BOOL)animated completion:(void(^)(void))completion {
    CGFloat duration = 0;
    if (animated) {
        duration = 0.25f;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            duration = 0.4f;
        }
    }
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration animations:^{
        CGRect rect = _slidingScrollView.frame;
        rect.origin.x = 0;
        _slidingScrollView.frame = rect;
    } completion:^(BOOL finished) {
        if (self.invisibleCloseSliderButton) {
            [self.invisibleCloseSliderButton removeFromSuperview];
            self.invisibleCloseSliderButton = nil;
        }
        _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
        _animating = NO;
        self.view.userInteractionEnabled = YES;
        [self didClose];
        if (completion) {
            completion();
        }
    }];
}

- (void)openSlider:(BOOL)animated completion:(void (^)(void))completion {
    [completion copy];
    if (_animating == NO && _isOpen == NO && _locked == NO) {
        [self willOpen];
        _animating = YES;
        _isOpen = YES; // Needs to be here to prevent bugs
        if (self.useBouncyAnimations) {
            [self openWithBouncyAnimation:animated completion:completion];
        } else {
            [self openWithSmoothAnimation:animated completion:completion];
        }
    } else {
        if (completion) {
            completion();
        }
    }
}

- (void)openWithBouncyAnimation:(BOOL)animated completion:(void(^)(void))completion {
    CGFloat duration1 = 0.0f;
    CGFloat duration2 = 0.0f;
    if (animated) {
        duration1 = 0.18f;
        duration2 = 0.18f;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            duration1 = duration1 * 1.5f;
            duration2 = duration2 * 1.5f;
        }
    }
    [UIView animateWithDuration:duration1  delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration  animations:^{
        CGRect aRect = _slidingScrollView.frame;
        aRect.origin.x = _sliderOpeningWidth + 10;
        _slidingScrollView.frame = aRect;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:duration2  delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration animations:^{
            CGRect rect = _slidingScrollView.frame;
            rect.origin.x = _sliderOpeningWidth;
            _slidingScrollView.frame = rect;
        } completion:^(BOOL finished2) {
            if (self.invisibleCloseSliderButton == nil) {
                [self addInvisibleButton];
            }
            _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
            _animating = NO;
            self.view.userInteractionEnabled = YES;
            [self didOpen];
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)openWithSmoothAnimation:(BOOL)animated completion:(void(^)(void))completion {
    CGFloat duration = 0.0f;
    if (animated) {
        duration = 0.25f;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            duration = 0.4f;
        }
    }
    [UIView animateWithDuration:duration  delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionOverrideInheritedDuration animations:^{
        CGRect rect = _slidingScrollView.frame;
        rect.origin.x = _sliderOpeningWidth;
        _slidingScrollView.frame = rect;
    } completion:^(BOOL finished) {
        if (self.invisibleCloseSliderButton == nil) {
            [self addInvisibleButton];
        }
        _animating = NO;
        self.view.userInteractionEnabled = YES;
        [self didOpen];
        if (completion) {
            completion();
        }
        
    }];
}

#pragma mark - Front & Back View Controller Changes

- (void)setFrontViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
    NSAssert(viewController, @"JSSlidingViewController requires both a front and a back view controller");
    UIViewController *newFrontViewController = viewController;
    CGRect frame = self.view.bounds;
    newFrontViewController.view.frame = CGRectMake(_sliderOpeningWidth, frame.origin.y, frame.size.width, frame.size.height);
    newFrontViewController.view.alpha = 0.0f;
    [self addChildViewController:newFrontViewController];
    [_slidingScrollView addSubview:newFrontViewController.view];
    CGFloat duration = 0.0f;
    if (animated) {
        duration = 0.25f;
    }
    [UIView animateWithDuration:duration animations:^{
        newFrontViewController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [_frontViewController willMoveToParentViewController:nil];
        [_frontViewController.view removeFromSuperview];
        [_frontViewController removeFromParentViewController];
        [newFrontViewController didMoveToParentViewController:self];
        _frontViewController = newFrontViewController;
    }];
}

- (void)setBackViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
    NSAssert(viewController, @"JSSlidingViewController requires both a front and a back view controller");
    UIViewController *newBackViewController = viewController;
    newBackViewController.view.frame = self.view.bounds;
    newBackViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addChildViewController:newBackViewController];
    [self.view insertSubview:newBackViewController.view atIndex:0];
    CGFloat duration = 0.0f;
    if (animated) {
        duration = 0.25f;
    }
    [UIView animateWithDuration:duration animations:^{
        _backViewController.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [_backViewController willMoveToParentViewController:nil];
        [_backViewController.view removeFromSuperview];
        [_backViewController removeFromParentViewController];
        [newBackViewController didMoveToParentViewController:self];
        _backViewController = newBackViewController;
    }];
}

#pragma mark - Will/Did Open/Close

- (void)willOpen {
    if (self.shouldTemporarilyRemoveBackViewControllerWhenClosed) {
        [self.view insertSubview:self.backViewController.view atIndex:0];
    }
    if ([self.delegate respondsToSelector:@selector(slidingViewControllerWillOpen:)]) {
        [self.delegate slidingViewControllerWillOpen:self];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:JSSlidingViewControllerWillOpenNotification object:self]];
}

- (void)didOpen {
    if ([self.delegate respondsToSelector:@selector(slidingViewControllerDidOpen:)]) {
        [self.delegate slidingViewControllerDidOpen:self];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:JSSlidingViewControllerDidOpenNotification object:self]];
}

- (void)willClose {
    if ([self.delegate respondsToSelector:@selector(slidingViewControllerWillClose:)]) {
        [self.delegate slidingViewControllerWillClose:self];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:JSSlidingViewControllerWillCloseNotification object:self]];
}

- (void)didClose {
    if (self.shouldTemporarilyRemoveBackViewControllerWhenClosed) {
        [self.backViewController.view removeFromSuperview];
    }
    if ([self.delegate respondsToSelector:@selector(slidingViewControllerDidClose:)]) {
        [self.delegate slidingViewControllerDidClose:self];
    }
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:JSSlidingViewControllerDidCloseNotification object:self]];
}

#pragma mark - Scroll View Delegate for the Sliding Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // BIG NASTY BUG IN iOS 6.x -- December 1, 2012 ~ JTS.
    // Under certain conditions, when nesting a table view inside of a scroll view,
    // as is frequently the case when using JSSlidingViewController,
    // scrollViewDidScroll: can be called from the outermost scrollView without scrollViewWillBeginDragging:
    // ever being called on that scrollView's delegate. Without knowing the internals of UIScrollView's implementation, the
    // best assumption we have is that the outer most scroll view (in our case the JSSlidingViewController's
    // slidingScrollView) does not "know" that it's scrolling (dragging/tracking methods aren't triggered
    // properly).
    
    // What the Bug Looks Like ---
    // When scrolling a table view inside the slidingScrollView, the slider may pop open and closed about 1 to 20 pixels
    // while scrolling, but never fully opening all the way. It's unusual to say the least. It's very difficult to reproduce
    // if your table view controller is inside a UINavigationController with a visible nav bar. Hiding the navigation bar
    // seems to make the issue more prominent.
    
    // How to Reproduce the Bug ---
    // 1) Nest a table view inside the slidingScrollView (it's okay if this tableview is inside of a UINavigationController).
    // 2) Present a full-screen modal view controller while the slider is closed.
    // 3) Dismiss the modal view controller
    // 4) Begin scrolling again on the tableview, quickly, in a semi-diagonal swipe direction
    //    that is 90 percent vertical.
    // 5) Observe the left hand edge of the screen for the jittery open/close while scrolling.
    
    // It's hard to reproduce, but trust me, it's there. I will follow up with Apple with a radar.
    
    // The following code doesn't "fix" the bug per se, but it will at least
    // make sure that the back view controller is visible if the back view controller's view is
    // set to be removed from the hierarchy when the slider is closed.
    
    // Note: December 9, 2012
    // We need to disable this bug correction during autorotation, since scrollViewDidScroll
    // is called as the slidingScrollView updates it's layout for a new interfaceOrientation. ~ JTS.
    
    if (self.isOpen == NO && self.isAnimatingInterfaceOrientation == NO) {
        CGPoint co = scrollView.contentOffset;
        if (co.x != self.sliderOpeningWidth) {
            [self scrollViewWillBeginDragging:scrollView];
            [self willOpen];
            _isOpen = YES;
            [self didOpen];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_animating == NO) {
        if (decelerate == YES) {
            // We'll handle the rest after it's done decelerating...
            self.view.userInteractionEnabled = NO;
        } else {
            CGPoint origin = self.frontViewController.view.frame.origin;
            origin = [_slidingScrollView convertPoint:origin toView:self.view];
            if (origin.x >= _sliderOpeningWidth) {
                if (self.invisibleCloseSliderButton == nil) {
                    [self addInvisibleButton];
                }
                CGRect rect = _slidingScrollView.frame;
                rect.origin.x = _sliderOpeningWidth;
                _slidingScrollView.frame = rect;
                _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
                _isOpen = YES;
            } else {
                if (self.invisibleCloseSliderButton) {
                    [self.invisibleCloseSliderButton removeFromSuperview];
                    self.invisibleCloseSliderButton = nil;
                }
                if (_isOpen) {
                    [self willClose];
                    _isOpen = NO;
                    [self didClose];
                }
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_animating == NO) {
        CGPoint origin = self.frontViewController.view.frame.origin;
        origin = [_slidingScrollView convertPoint:origin toView:self.view];
        if ( (origin.x >= _sliderOpeningWidth) && (scrollView.dragging == NO) ){
            if (self.invisibleCloseSliderButton == nil) {
                [self addInvisibleButton];
            }
            CGRect rect = _slidingScrollView.frame;
            rect.origin.x = _sliderOpeningWidth;
            _slidingScrollView.frame = rect;
            _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
            _isOpen = YES;
        } else {
            if (self.invisibleCloseSliderButton) {
                [self.invisibleCloseSliderButton removeFromSuperview];
                self.invisibleCloseSliderButton = nil;
            }
            if (_isOpen) {
                [self willClose];
                _isOpen = NO;
                [self didClose];
            }
        }
        self.view.userInteractionEnabled = YES;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isOpen == YES && _locked == NO) {
        CGRect rect = _slidingScrollView.frame;
        rect.origin.x = 0;
        _slidingScrollView.frame = rect;
        _slidingScrollView.contentOffset = CGPointMake(0, 0);
        if (self.invisibleCloseSliderButton) {
            [self.invisibleCloseSliderButton removeFromSuperview];
            self.invisibleCloseSliderButton = nil;
        }
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:JSSlidingViewControllerWillBeginDraggingNotification object:self]];
    
    if (_locked == NO) {
        if (_isOpen == YES) {
            CGRect rect = _slidingScrollView.frame;
            rect.origin.x = 0;
            _slidingScrollView.frame = rect;
            _slidingScrollView.contentOffset = CGPointMake(0, 0);
            if (self.invisibleCloseSliderButton) {
                [self.invisibleCloseSliderButton removeFromSuperview];
                self.invisibleCloseSliderButton = nil;
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_isOpen == YES && _locked == NO) {
        if (self.invisibleCloseSliderButton == nil) {
            [self addInvisibleButton];
        }
        CGRect rect = _slidingScrollView.frame;
        rect.origin.x = _sliderOpeningWidth;
        _slidingScrollView.frame = rect;
        _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
    }
    [super touchesEnded:touches withEvent:event];
}

#pragma mark - Convenience

- (void)setupSlidingScrollView {
    CGRect frame = self.view.bounds;
    [self setWidthOfVisiblePortionOfFrontViewControllerWhenSliderIsOpen:JSSlidingViewControllerDefaultVisibleFrontPortionWhenOpen];
    self.slidingScrollView = [[SlidingScrollView alloc] initWithFrame:frame];
    _slidingScrollView.contentOffset = CGPointMake(_sliderOpeningWidth, 0);
    _slidingScrollView.contentSize = CGSizeMake(frame.size.width + _sliderOpeningWidth, frame.size.height);
    _slidingScrollView.delegate = self;
    [self.view insertSubview:_slidingScrollView atIndex:0];
    _isOpen = NO;
    _locked = NO;
    _animating = NO;
    _frontViewControllerHasOpenCloseNavigationBarButton = YES;
    _allowManualSliding = YES;
    
    self.frontViewControllerDropShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frontViewControllerDropShadow.png"]];
    self.frontViewControllerDropShadow.frame = CGRectMake(_sliderOpeningWidth - JSSlidingViewControllerDropShadowImageWidth, 0.0f, JSSlidingViewControllerDropShadowImageWidth, _slidingScrollView.bounds.size.height);
    [_slidingScrollView addSubview:self.frontViewControllerDropShadow];
    
    self.frontViewControllerDropShadow_right = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frontViewControllerDropShadow.png"]];
    self.frontViewControllerDropShadow_right.frame = CGRectMake(_sliderOpeningWidth + frame.size.width, 0.0f, JSSlidingViewControllerDropShadowImageWidth, _slidingScrollView.bounds.size.height);
    self.frontViewControllerDropShadow_right.transform = CGAffineTransformMakeRotation(M_PI);
    [_slidingScrollView addSubview:self.frontViewControllerDropShadow_right];
}

- (void)setFrontViewControllerHasOpenCloseNavigationBarButton:(BOOL)frontViewControllerHasOpenCloseNavigationBarButton {
    if (_frontViewControllerHasOpenCloseNavigationBarButton != frontViewControllerHasOpenCloseNavigationBarButton) {
        _frontViewControllerHasOpenCloseNavigationBarButton = frontViewControllerHasOpenCloseNavigationBarButton;
        if (self.invisibleCloseSliderButton.superview) {
            [self removeInvisibleButton];
            [self addInvisibleButton];
        }
    }
}

- (void)addInvisibleButton {
    self.invisibleCloseSliderButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.invisibleCloseSliderButton.showsTouchWhenHighlighted = NO;
    CGFloat yOrigin = 0.0f;
    if (_frontViewControllerHasOpenCloseNavigationBarButton) {
        yOrigin = 44.0f;
    }
    self.invisibleCloseSliderButton.frame = CGRectMake(self.frontViewController.view.frame.origin.x, yOrigin, _desiredVisiblePortionOfFrontViewWhenOpen, self.view.frame.size.height - yOrigin);
    self.invisibleCloseSliderButton.backgroundColor = [UIColor clearColor];
    self.invisibleCloseSliderButton.isAccessibilityElement = YES;
    self.invisibleCloseSliderButton.accessibilityLabel = self.localizedAccessibilityLabelForInvisibleCloseSliderButton;
    [self.invisibleCloseSliderButton addTarget:self action:@selector(invisibleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_slidingScrollView addSubview:self.invisibleCloseSliderButton];
}

- (void)removeInvisibleButton {
    [self.invisibleCloseSliderButton removeFromSuperview];
    self.invisibleCloseSliderButton = nil;
}

- (void)invisibleButtonPressed {
    if (_locked == NO) {
        [self closeSlider:YES completion:nil];
    }
}

- (void)setWidthOfVisiblePortionOfFrontViewControllerWhenSliderIsOpen:(CGFloat)width {
    CGFloat startingVisibleWidth = _sliderOpeningWidth;
    self.desiredVisiblePortionOfFrontViewWhenOpen = width;
    _sliderOpeningWidth = self.view.bounds.size.width - self.desiredVisiblePortionOfFrontViewWhenOpen;
    if (startingVisibleWidth != _sliderOpeningWidth) {
        [self updateInterface];
    }
}

- (void)setLocked:(BOOL)locked {
    _locked = locked;
    if (_allowManualSliding && locked == NO) {
        _slidingScrollView.scrollEnabled = YES;
    } else {
        _slidingScrollView.scrollEnabled = NO;
    }
}

- (void)setAllowManualSliding:(BOOL)allowManualSliding {
    _allowManualSliding = allowManualSliding;
    _slidingScrollView.scrollEnabled = allowManualSliding;
}

- (UIViewController *)frontViewController {
    return _frontViewController;
}

- (UIViewController *)backViewController {
    return _backViewController;
}

#pragma mark - Accessiblility

- (BOOL)accessibilityPerformEscape {
    [self closeSlider:YES completion:nil];
    return YES;
}

- (NSString *)localizedAccessibilityLabelForInvisibleCloseSliderButton {
    NSString *locTitle = nil;
    if ([self.delegate respondsToSelector:@selector(localizedAccessibilityLabelForInvisibleCloseSliderButton:)]) {
        locTitle = [self.delegate localizedAccessibilityLabelForInvisibleCloseSliderButton:self];
    }
    if (locTitle.length == 0) {
        locTitle = @"Visible Edge of Main Content";
    }
    return locTitle;
}

@end








