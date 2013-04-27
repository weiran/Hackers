//
//  JSSlidingViewController.h
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
// SLIDING SCROLL VIEW DISCUSSION

// Nota Bene:
// Some of these scroll view delegate method implementations may look quite strange, but
// it has to do with the peculiarities of the timing and circumstances of UIScrollViewDelegate
// callbacks. Numerous bugs and unusual edge cases have been accounted for via rigorous testing.
// Edit them with extreme care, at your own risk.
//
// How It Works:
//
// 1. The slidingScrollView is a container for the frontmost content. The backmost content is not a part of the
// slidingScrollView's hierarchy. The slidingScrollView has a clear background color, which masks the technique I'm using.
// To make it easier to see what's happening, try temporarily setting it's background color to a semi-translucent color
// in the -(void)setupSlidingScrollView method.
//
// 2. When the slider is closed and at rest, the scroll view's frame fills the display.
//
// 3. When the slider is open and at rest, the scroll view's frame is snapped over to the right,
// starting at an x origin of 262.
//
// 4. When the slider is being opened or closed and is tracking a dragging touch, the scroll view's frame fills
// the display.
//
// 5a. When the slider has finished animating/decelerating to either the closed or open position, the
// UIScrollView delegate callbacks are used to determine what to do next.
// 5b. If the slider has come to rest in the open position, the scroll view's frame's x origin is set to the value
// in #3, and an "invisible button" is added over the visible portion of the main content
// to catch touch events and trigger a close action.
// 5c. If the slider has come to rest in the closed position, the invisible button is removed, and the
// scroll view's frame once again fills the display.
//
// 6. Numerous edge cases were solved for, most of them related to what happens when touches/drags
// begin or end before the slider has finished decelerating (in either direction).
//
// 7a. Changes to the scroll view frame or the invisible button are also triggered by UIView touch event
// methods like touchesBegan and touchesEnded.
// 7b. Since not every touch sequence turns into a drag, responses to these touch events must perform
// some of the same functions as responses to scroll view delegate methods. This explains why there is
// some overlap between the two kinds of sequences.
//
// Summary:
//
// By combining UIScrollViewDelegate methods and UIView touch event methods, I am able to mimic the slide-to-reveal
// navigation that is currently in-vogue, but without having to manually track touches and calculate dragging & decelerating
// animations. Apple's own implementation of UIScrollView touch tracking is infinitely smoother and richer than any
// third party library.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//

#import <UIKit/UIKit.h>

extern  NSString *   const JSSlidingViewControllerWillOpenNotification;
extern  NSString *   const JSSlidingViewControllerWillCloseNotification;
extern  NSString *   const JSSlidingViewControllerDidOpenNotification;
extern  NSString *   const JSSlidingViewControllerDidCloseNotification;
extern  NSString *   const JSSlidingViewControllerWillBeginDraggingNotification;
extern  CGFloat      const JSSlidingViewControllerDefaultVisibleFrontPortionWhenOpen;
extern  CGFloat      const JSSlidingViewControllerDropShadowImageWidth;


@interface SlidingScrollView : UIScrollView
@end


@protocol JSSlidingViewControllerDelegate;


@interface JSSlidingViewController : UIViewController

// @property (nonatomic, assign) BOOL locked;
// If YES, the slider cannot be opened, either manually or programmatically. The default is NO.
@property (nonatomic, assign) BOOL locked;

// @property (nonatomic, assign) BOOL frontViewControllerHasOpenCloseNavigationBarButton;
// Set this to NO if your front view controller does not have a hamburger button as its left navigation item.
// Defaults to YES.
@property (nonatomic, assign) BOOL frontViewControllerHasOpenCloseNavigationBarButton;

// @property (nonatomic, assign) BOOL allowManualSliding;
// Set this to NO if you only want programmatic opening/closing of the slider
@property (nonatomic, assign) BOOL allowManualSliding;

// @property (nonatomic, assign) BOOL useBouncyAnimations;
// Set this to NO if you don't want to see the inertial bounce style animations when the slider is opened
// or closed programmatically. Defaults to YES. Bouncy animations are not applied to deceleration animations
// after a manual change (only programmatic open/close animations).
@property (nonatomic, assign) BOOL useBouncyAnimations;

// @property (nonatomic, assign) BOOL shouldTemporarilyRemoveBackViewControllerWhenClosed;
// Set this to YES if you want the back view controller to be removed from the view hierarchy when the
// slider is closed. This is generally only necessary for VoiceOver reasons (to prevent VO from speaking
// the content of the back view controller when the slider is closed. Defaults to NO.
@property (nonatomic, assign) BOOL shouldTemporarilyRemoveBackViewControllerWhenClosed;

// @property (nonatomic, assign, readonly) BOOL animating;
// Returns YES if the slider is animating open or shut.
@property (nonatomic, assign, readonly) BOOL animating;

// @property (nonatomic, assign, readonly) BOOL isOpen;
// Returns YES if the slider is open, i.e., the back view controller is visible.
@property (nonatomic, assign, readonly) BOOL isOpen;

// @property (nonatomic, strong, readonly) UIViewController *frontViewController;
// The front view controller (generally, a UINavigationController with a hamburger button).
@property (nonatomic, strong, readonly) UIViewController *frontViewController;

// @property (nonatomic, strong, readonly) UIViewController *backViewController;
// The back view controller (generally, a UITableViewController serving as a main menu).
@property (nonatomic, strong, readonly) UIViewController *backViewController;

// @property (nonatomic, strong, readonly) SlidingScrollView *slidingScrollView;
// A UIScrollView subclass used to contain the front view controller. Secret sauce ingredient.
@property (nonatomic, strong, readonly) SlidingScrollView *slidingScrollView;

// @property (nonatomic, weak) id<JSSlidingViewControllerDelegate> delegate;
// See the protocol desription below. All delegate methods are optional.
@property (nonatomic, weak) id<JSSlidingViewControllerDelegate> delegate;

// - (id)initWithFrontViewController:(UIViewController *)frontVC backViewController:(UIViewController *)backVC;
// The designated initializer. Both front and back view controllers are required or an exception will be thrown.
- (id)initWithFrontViewController:(UIViewController *)frontVC backViewController:(UIViewController *)backVC;

// - (void)closeSlider:(BOOL)animated completion:(void (^)(void))completion;
// Closes the slider, with optional animation and a completion block.
- (void)closeSlider:(BOOL)animated completion:(void (^)(void))completion;

// - (void)openSlider:(BOOL)animated completion:(void (^)(void))completion;
// Opens the slider, with optional animation and a completion block.
- (void)openSlider:(BOOL)animated completion:(void (^)(void))completion;

// - (void)setFrontViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;
// Sets the front view controller with optional crossfade animation and a completion block.
// viewController cannot be nil.
- (void)setFrontViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;

// - (void)setBackViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;
// Sets the back view controller with optional crossfade animation and a completion block.
// viewController cannot be nil.
- (void)setBackViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;

// - (void)setWidthOfVisiblePortionOfFrontViewControllerWhenSliderIsOpen:(CGFloat)width;
// Sets the width of the visible portion of the front view controller when the slider is in the open position.
// Setting this value will not change the currently visible portion of the slider if it is already open. It will be
// applied the next time the slider comes to rest in the open position. You probably only need to call this once,
// or never if you are happy with the default portion (58.0f).
- (void)setWidthOfVisiblePortionOfFrontViewControllerWhenSliderIsOpen:(CGFloat)width;

@end


@protocol JSSlidingViewControllerDelegate <NSObject>

// Note: The will/did open/close methods are called *after* any completion blocks have been performed.

@optional

// - (void)slidingViewControllerWillOpen:(JSSlidingViewController *)viewController;
// Called before the slider is opened (programmatically or manually)
- (void)slidingViewControllerWillOpen:(JSSlidingViewController *)viewController;

// - (void)slidingViewControllerWillClose:(JSSlidingViewController *)viewController;
// Called before the slider is closed (programmatically or manually)
- (void)slidingViewControllerWillClose:(JSSlidingViewController *)viewController;

// - (void)slidingViewControllerDidOpen:(JSSlidingViewController *)viewController;
// Called after the slider is opened (programmatically or manually)
- (void)slidingViewControllerDidOpen:(JSSlidingViewController *)viewController;

// - (void)slidingViewControllerDidClose:(JSSlidingViewController *)viewController;
// Called after the slider is closed (programmatically or manually)
- (void)slidingViewControllerDidClose:(JSSlidingViewController *)viewController;

// - (NSUInteger)supportedInterfaceOrientationsForSlidingViewController:(JSSlidingViewController *)viewController;
// Unless you override, JSSlidingViewController uses UIInterfaceOrientationMaskPortrait for iPhone and all 4 orientations for iPad.
- (NSUInteger)supportedInterfaceOrientationsForSlidingViewController:(JSSlidingViewController *)viewController;

// - (NSUInteger)supportedInterfaceOrientationsForSlidingViewController:(JSSlidingViewController *)viewController;
// Unless you override, JSSlidingViewController uses YES for portrait on iPhone and YES for all 4 orientations for iPad.
- (BOOL)slidingViewController:(JSSlidingViewController *)viewController shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

// - (NSString *)localizedAccessibilityLabelForInvisibleCloseSliderButton:(JSSlidingViewController *)
// The "invisible button" is the clear button overlaid on the visible edge of the front view controller
// when the slider is open. For a better experience when using voice over, override this method to
// return a localized label for this button. If you don't override, "Visible Edge of Main Content" will be used.
- (NSString *)localizedAccessibilityLabelForInvisibleCloseSliderButton:(JSSlidingViewController *)viewController;

@end









