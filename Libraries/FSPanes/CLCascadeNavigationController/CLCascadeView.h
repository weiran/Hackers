//
//  CLCascadeView.h
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSPanes/Other/CLScrollView.h"
#import "FSPanes/Other/CLGlobal.h"

@protocol CLCascadeViewDataSource;
@protocol CLCascadeViewDelegate;

@interface CLCascadeView : UIView <UIScrollViewDelegate> {
    // delegate and dataSource
    id<CLCascadeViewDelegate> __unsafe_unretained _delegate;
    id<CLCascadeViewDataSource> __unsafe_unretained _dataSource;

    // scroll view
    CLScrollView* _scrollView;
    
    // contain all pages, if page is unloaded then page is respresented as [NSNull null]
    NSMutableArray* _pages;
    
    //sizes
    CGFloat _pageWidth;
    CGFloat _leftInset;
    CGFloat _widerLeftInset;

    BOOL _pullToDetachPages;

@private
    struct {
        unsigned int willDetachPages:1;
        unsigned int isDetachPages:1;
        unsigned int hasWiderPage:1;
    } _flags;

    NSInteger _indexOfFirstVisiblePage;
    NSInteger _indexOfLastVisiblePage;
}

@property(nonatomic, unsafe_unretained) id<CLCascadeViewDelegate> delegate;
@property(nonatomic, unsafe_unretained) id<CLCascadeViewDataSource> dataSource;

/*
 * Left inset of normal page from left boarder. Default 58.0f
 * If you change this property, width of page will change
 */
@property(nonatomic) CGFloat leftInset;

/*
 * Left inset of wider page from left boarder. Default 220.0f
 */
@property(nonatomic) CGFloat widerLeftInset;

/*
 * If YES, then pull to detach pages is enabled, default YES
 */
@property(nonatomic, assign) BOOL pullToDetachPages;


- (void) pushPage:(UIView*)newPage fromPage:(UIView*)fromPage animated:(BOOL)animated;
- (void) pushPage:(UIView*)newPage fromPage:(UIView*)fromPage animated:(BOOL)animated viewSize:(CLViewSize)viewSize;

- (void) popPageAtIndex:(NSInteger)index animated:(BOOL)animated;
- (void) popAllPagesAnimated:(BOOL)animated;

- (UIView*) loadPageAtIndex:(NSInteger)index;

- (void) unloadInvisiblePages;

- (NSInteger) indexOfFirstVisibleView:(BOOL)loadIfNeeded;
- (NSInteger) indexOfLastVisibleView:(BOOL)loadIfNeeded;
- (NSArray*) visiblePages;

- (void) updateContentLayoutToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;

- (BOOL) canPopPageAtIndex:(NSInteger)index; // @dodikk
@end

@protocol CLCascadeViewDataSource <NSObject>
@required
- (UIView*) cascadeView:(CLCascadeView*)cascadeView pageAtIndex:(NSInteger)index;
- (NSInteger) numberOfPagesInCascadeView:(CLCascadeView*)cascadeView;
@end

@protocol CLCascadeViewDelegate <NSObject>
@optional
- (void) cascadeView:(CLCascadeView*)cascadeView didLoadPage:(UIView*)page;
- (void) cascadeView:(CLCascadeView*)cascadeView didUnloadPage:(UIView*)page;

- (void) cascadeView:(CLCascadeView*)cascadeView didAddPage:(UIView*)page animated:(BOOL)animated;
- (void) cascadeView:(CLCascadeView*)cascadeView didPopPageAtIndex:(NSInteger)index;

/*
 * Called when page will be unveiled by another page or will slide in CascadeView bounds
 */
- (void) cascadeView:(CLCascadeView*)cascadeView pageDidAppearAtIndex:(NSInteger)index;
/*
 * Called when page will be shadowed by another page or will slide out CascadeView bounds
 */
- (void) cascadeView:(CLCascadeView*)cascadeView pageDidDisappearAtIndex:(NSInteger)index;

/*
 */
- (void) cascadeViewDidStartPullingToDetachPages:(CLCascadeView*)cascadeView;
- (void) cascadeViewDidPullToDetachPages:(CLCascadeView*)cascadeView;
- (void) cascadeViewDidCancelPullToDetachPages:(CLCascadeView*)cascadeView;

@end
