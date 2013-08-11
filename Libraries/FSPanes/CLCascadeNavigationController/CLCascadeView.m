//
//  CLCascadeView.m
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CLCascadeView.h"
#import "CLSegmentedView.h"
#import "CLGlobal.h"

@interface CLCascadeView (DelegateMethods)
- (void) didLoadPage:(UIView*)page;
- (void) didAddPage:(UIView*)page animated:(BOOL)animated;
- (void) didPopPageAtIndex:(NSInteger)index;
- (void) didUnloadPage:(UIView*)page;
- (void) pageDidAppearAtIndex:(NSInteger)index;
- (void) pageDidDisappearAtIndex:(NSInteger)index;
- (void) didStartPullingToDetachPages;
- (void) didPullToDetachPages;
- (void) didCancelPullToDetachPages;
- (void) sendAppearanceDelegateMethodsIfNeeded;
- (void) sendDetachDelegateMethodsIfNeeded;
@end

@interface CLCascadeView (Private)
- (NSArray*) pagesOnStock;

- (BOOL) pageExistAtIndex:(NSInteger)index;
- (void) unloadInvisiblePagesOnStock;
- (void) unloadPageIfNeeded:(NSInteger)index;

- (NSInteger) normalizePageIndex:(NSInteger)index;
- (CGSize) calculatePageSize:(UIView*)view;
- (CGSize) calculateContentSize;
- (UIEdgeInsets) calculateEdgeInset:(UIInterfaceOrientation)interfaceOrientation;
- (CGPoint) calculateOriginOfPageAtIndex:(NSInteger)index;

- (void) setProperContentSize;
- (void) setProperEdgeInset:(BOOL)animated;
- (void) setProperEdgeInset:(BOOL)animated forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void) setProperSizesForLoadedPages:(UIInterfaceOrientation)interfaceOrientation;

- (CLSegmentedView *)createPageFromView:(UIView*)view size:(CLViewSize)viewSize;
- (void) unloadPage:(CLSegmentedView*)page remove:(BOOL)remove;
- (void) loadBoundaryPagesIfNeeded;

- (NSInteger) indexOfFirstVisiblePage;
- (NSInteger) visiblePagesCount;
- (CGFloat) widerPageWidth;

- (void) setProperPositionOfPageAtIndex:(NSInteger)index;
@end

#define DEFAULT_LEFT_INSET 58.0f
#define DEFAULT_WIDER_LEFT_INSET 220.0f
#define PULL_TO_DETACH_FACTOR 0.32f

//#define CONTESTED_CASE

@implementation CLCascadeView

@synthesize leftInset = _leftInset; 
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize widerLeftInset = _widerLeftInset;
@synthesize pullToDetachPages = _pullToDetachPages;

#pragma mark -
#pragma mark Init & dealloc

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    _delegate = nil;
    _dataSource = nil;    
    _scrollView = nil;
    _pages = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _pages = [[NSMutableArray alloc] init];

        _flags.willDetachPages = NO;
        _flags.isDetachPages = NO;
        _flags.hasWiderPage = NO;

        _indexOfFirstVisiblePage = -1;
        _indexOfLastVisiblePage = -1;

        _scrollView = [[CLScrollView alloc] init]; // frame will be set in setter of _leftInset
        [_scrollView setDelegate: self];
        
        self.leftInset = DEFAULT_LEFT_INSET;
        self.widerLeftInset = DEFAULT_WIDER_LEFT_INSET;
        self.pullToDetachPages = YES;
        
        [self addSubview: _scrollView];
                
        [self setAutoresizingMask:
         UIViewAutoresizingFlexibleLeftMargin | 
         UIViewAutoresizingFlexibleRightMargin | 
         UIViewAutoresizingFlexibleBottomMargin | 
         UIViewAutoresizingFlexibleTopMargin | 
         UIViewAutoresizingFlexibleWidth | 
         UIViewAutoresizingFlexibleHeight];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = nil;
    
    NSEnumerator *enumerator = [[self visiblePages] reverseObjectEnumerator];
    
    UIView *page;
    while (page = [enumerator nextObject]) {
        CGRect rect = [_scrollView convertRect:page.frame toView:self];
        
        if (CGRectContainsPoint(rect, point)) {
            CGPoint newPoint = [self convertPoint:point toView:page];
            view = [page hitTest:newPoint withEvent:event];
            break;
        }
    }
    
    if (view != nil) {
        return view;
    }
    else {
        return [super hitTest:point withEvent:event];
    }
}

#pragma mark -
#pragma mark Class methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pushPage:(UIView*)newPage fromPage:(UIView*)fromPage animated:(BOOL)animated {
    [self pushPage:newPage fromPage:fromPage animated:animated viewSize:CLViewSizeNormal];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pushPage:(UIView*)newPage fromPage:(UIView*)fromPage animated:(BOOL)animated viewSize:(CLViewSize)viewSize {
    // put the newPage view into a segmentedView container
    CLSegmentedView *newPageContainer = [self createPageFromView:newPage size:viewSize];
    
    if (viewSize == CLViewSizeWider) {
        _flags.hasWiderPage = YES;
    }
    
    NSInteger index = [_pages count];
    CGSize size = [self calculatePageSize: newPageContainer];
    CGPoint origin = [self calculateOriginOfPageAtIndex: index];
    CGRect frame = CGRectMake(origin.x, origin.y, size.width, size.height);
    
    if (fromPage == nil) {
        [self popAllPagesAnimated: animated];
        frame.origin.x = 0.0f;
    }
    
    // animation, from left to right
    if (animated && (fromPage == nil) && (([_scrollView contentOffset].x >= 0))) {
        // start frame animation
        CGRect startRect = CGRectMake(origin.x - size.width, origin.y, size.width, size.height);
        // set new page frame
        [newPageContainer setFrame: startRect];
        // animation
        [UIView animateWithDuration:0.15 
                         animations: ^{
                             // set new page frame aimated
                             [newPageContainer setFrame: frame];
                         }];
    } else {
        // set new page frame
        [newPageContainer setFrame: frame];
    }
    
    // add page to array of pages
    [_pages addObject: newPageContainer];
    // update content size
    [self setProperContentSize];
    // update edge inset
    [self setProperEdgeInset: NO];
    // add subview
    [_scrollView addSubview: newPageContainer];
    // send message to delegate
    [self didAddPage:newPageContainer animated:animated];
    
    UIInterfaceOrientation interfaceOrienation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (index > 0) {
        // scroll to new page frame
        if (!_flags.hasWiderPage) {
            if (UIInterfaceOrientationIsPortrait(interfaceOrienation)) {
                [_scrollView setContentOffset:CGPointMake(index * _pageWidth - (self.bounds.size.width - _pageWidth - _leftInset), 0.0f) animated:animated];
            } else {
                [_scrollView setContentOffset:CGPointMake(index * _pageWidth - _pageWidth, 0.0f) animated:animated];
            }
        } else {
            if (UIInterfaceOrientationIsPortrait(interfaceOrienation)) {
                [_scrollView setContentOffset:CGPointMake(index * _pageWidth - _widerLeftInset + _leftInset, 0.0f) animated:animated];
            } else {
                [_scrollView setContentOffset:CGPointMake(index * _pageWidth + _pageWidth  - ([self widerPageWidth]) - _leftInset + _widerLeftInset, 0.0f) animated:animated];
            }
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) popPageAtIndex:(NSInteger)index animated:(BOOL)animated {
    if ([_pages count] == 0) return;

    // normalize index - by @dodikk
    index = [self normalizePageIndex: index];
    
    // get item at index
    __unsafe_unretained CLSegmentedView *page = [_pages objectAtIndex:index];
    
    // check if page is unloaded
    if (page.isLoaded) {
        
        if (animated) {
            // animate pop
            [UIView animateWithDuration:0.4f 
                             animations:^ {
                                 [page setAlpha: 0.0f];
                             }
                             completion:^(BOOL finished) {
                                 // unload and remove page
                                 [self unloadPage:page remove:YES];
                                 // update edge inset
                                 [self setProperEdgeInset: NO];
                                 // send delegate message
                                 [self didPopPageAtIndex: index];
                             }];
            
        } else {
            // unload and remove page
            [self unloadPage:page remove:YES];
            // update edge inset
            [self setProperEdgeInset: NO];
            // send delegate message
            [self didPopPageAtIndex: index];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) popAllPagesAnimated:(BOOL)animated {
    // index of last page
    NSUInteger index = [_pages count] - 1;
    // pop page from back
    NSEnumerator* enumerator = [_pages reverseObjectEnumerator];
    // enumarate pages
    while ([enumerator nextObject]) {
        // pop page at index
        [self popPageAtIndex:index animated:NO];
        index--;
    }    
    
    [_pages removeAllObjects];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) loadPageAtIndex:(NSInteger)index {
    UIView *page = nil; // nil == index out of range
    
    // check the page exists
    if ([self pageExistAtIndex:index]) {
        CLSegmentedView *page = [_pages objectAtIndex:index];
        
        // rebuild page if necessery
        if (page.contentView == nil) {
            // get page from dataSource
            UIView* view = [_dataSource cascadeView:self pageAtIndex:index];
            
            if (view != nil) {
                //preventive, set frame
                CGSize pageSize = [self calculatePageSize:page];
                CGRect pageFrame = CGRectMake(index * _pageWidth, 0.0f, pageSize.width, pageSize.height);
                page.frame = pageFrame;
                
                page.contentView = view;

                // calculate direction of movement (if move left add view at index 0 else add at last position)
                if ((_scrollView.contentOffset.x + _scrollView.contentInset.left) > index * _pageWidth) {
                    // add subview
                    [_scrollView insertSubview:page atIndex:0];
                }
                else {
                    // add subview
                    [_scrollView addSubview:page];
                }
                
                // send delegate
                [self didLoadPage:view];
            }
        }
    }
    
    return page;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadInvisiblePages {
    
    BOOL canUnload = YES;
    
    // temp array with pages to unload
    NSMutableArray* pagesToUnload = [NSMutableArray array];
    
    // get array of visible pages
    NSArray* visiblePages = [self visiblePages];
    
    // if visible page exist in array of pages then can't unload
    for (CLSegmentedView *page in _pages) {
        
        if (page.isLoaded) {
            
            for (UIView* visiblePage in visiblePages) {
                
                if (page == visiblePage) {
                    canUnload = NO;
                    break;
                }
            }
            // if can, add to array - pages to unlaod
            if (canUnload) {
                [pagesToUnload addObject:page];
            } 
            // set flag to YES
            canUnload = YES;
        }
    }
    
    // unload pages
    // check if page contain in array of visible pages
    [pagesToUnload enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self unloadPage:obj remove:NO];
    }];
    
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    /*
     * dodikk update -  Added size adjustments on layoutSubviews
     */
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation]; 
    
    // recalculate pages height and width
    [self setProperSizesForLoadedPages:interfaceOrientation];
    
    [[self visiblePages] makeObjectsPerformSelector:@selector(setNeedsLayout)];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) updateContentLayoutToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    // set proper content size
    [self setProperContentSize];
    // set proper edge inset
    [self setProperEdgeInset:YES forInterfaceOrientation:interfaceOrientation];
    // recalculate pages height and width
    [self setProperSizesForLoadedPages: interfaceOrientation];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) canPopPageAtIndex:(NSInteger)index {
    NSRange range = {0, [_pages count]};
    return NSLocationInRange(index, range);
}

#pragma mark -
#pragma mark Private methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadPageIfNeeded:(NSInteger)index {
    CLSegmentedView *page = [_pages objectAtIndex: index];
    
    // if page is unloaded, do nothing
    if (page.isLoaded == NO) return;
    
    // load all visible pages
    NSArray* visiblePages = [self visiblePages];
    BOOL pageIsVisible = NO;
    
    // check if page contain in array of visible pages
    for (UIView* page in visiblePages) {
        NSUInteger pageIndex = [_pages indexOfObject: page];
        if (pageIndex != NSNotFound) {
            pageIsVisible = YES; break;
        }
    }
    
    // if page don't contain in array of visible pages, then unloadPage
    if (!pageIsVisible) {
        [self unloadPage:page remove:NO];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) indexOfFirstVisibleView:(BOOL)loadIfNeeded {
    // calculate first visible page
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    
    if ([self pageExistAtIndex: firstVisiblePageIndex]) {
        
        if (loadIfNeeded) {
            // get first visible page
            CLSegmentedView* page = [_pages objectAtIndex: firstVisiblePageIndex];
            
            // chceck if is loaded, and load if needed
            if (page.isLoaded == NO) {
                [self loadPageAtIndex: firstVisiblePageIndex];
            }
        }        
        
        return firstVisiblePageIndex;
    } 
    
    return NSNotFound;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) indexOfLastVisibleView:(BOOL)loadIfNeeded {
    // calculate visible pages count, first visible and last visible page
    NSInteger visiblePagesCount = [self visiblePagesCount];
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    NSInteger lastVisiblePageIndex = MIN([_pages count]-1, firstVisiblePageIndex + visiblePagesCount -1);
    return lastVisiblePageIndex;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) visiblePagesCount {
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    return ceil((_scrollView.contentOffset.x - firstVisiblePageIndex * _pageWidth + _pageWidth - _scrollView.contentInset.right) / _pageWidth) + 1;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger) indexOfFirstVisiblePage {
    // calculate first visible page
    CGFloat contentOffset = _scrollView.contentOffset.x;// + _scrollView.contentInset.left;
    NSInteger index = floor((contentOffset) / _pageWidth);

    return (index < 0) ? 0 : index;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray*) visiblePages {
    
    // calculate first visible page and visible page count
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    NSInteger visiblePagesCount = [self visiblePagesCount];
    
    // create array
    NSMutableArray* array = [NSMutableArray array];
    
    for (NSInteger i=firstVisiblePageIndex; i<=visiblePagesCount + firstVisiblePageIndex - 1; i++) {
        
        // check if page index is in bounds 
        if ([self pageExistAtIndex: i]) {
            // get page at index
            id item = [_pages objectAtIndex: i];
            
            // add page to array if could load
            if (item) {
                [array addObject: item];
            }
        }
    }
    
    // return array of visible pages
    return array;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) loadBoundaryPagesIfNeeded {
    CLSegmentedView* page = nil;
    
    // calculate first visible page
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];

    if ([self pageExistAtIndex: firstVisiblePageIndex]) {
        // get first visible page
        page = [_pages objectAtIndex: firstVisiblePageIndex];
        
        // load if needed
        if (page.isLoaded == NO) {
            [self loadPageAtIndex: firstVisiblePageIndex];
        }
        
        // calculate last visible page
        NSInteger lastVisiblePageIndex = [self indexOfLastVisibleView: NO];
        
        // check if first page is last page    
        if (lastVisiblePageIndex != firstVisiblePageIndex) {
            // get last visible page
            page = [_pages objectAtIndex: lastVisiblePageIndex];
            
            // load if needed
            if (page.isLoaded == NO) {
                [self loadPageAtIndex: lastVisiblePageIndex];
            }
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray*) pagesOnStock {
    
    // clalculate first visible page index
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    
    // create array
    NSMutableArray* array = [NSMutableArray array];
    
    for (NSInteger i=0; i<=firstVisiblePageIndex; i++) {
        
        // check if page index is in bounds 
        if ([self pageExistAtIndex: i]) {
            // get page at index
            id item = [_pages objectAtIndex: i];
            
            // adds all parties, even if they are not loaded
            [array addObject: item];
        }
    }
    
    // return array of visible pages
    return array;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) pageExistAtIndex:(NSInteger)index {
    return (([_pages count] > 0) &&
            (index >= 0) && 
            (index <= [_pages count] - 1));
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setProperContentSize { 
    // set proper content size
    _scrollView.contentSize = [self calculateContentSize];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize) calculateContentSize {

    CGFloat width = 0.0f;
    
    if (!_flags.hasWiderPage) {
        width = ([_pages count] -1) * _pageWidth;
    } else {
        width = ([_pages count] -1) * _pageWidth + ([self widerPageWidth] - _pageWidth);
    }
    
//    return CGSizeMake(width, UIInterfaceOrientationIsPortrait(interfaceOrientation) ? self.bounds.size.height : self.bounds.size.height);
    return CGSizeMake(width, 0.0f);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setProperEdgeInset:(BOOL)animated {
    // get current interface orientation
    UIInterfaceOrientation interfaceOrienation = [[UIApplication sharedApplication] statusBarOrientation];
    // set proper edge inset for orientation
    [self setProperEdgeInset:animated forInterfaceOrientation:interfaceOrienation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setProperEdgeInset:(BOOL)animated forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // check if animated, change content inset
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^ {
            _scrollView.contentInset = [self calculateEdgeInset:interfaceOrientation];   
        }];
    } else {
        _scrollView.contentInset = [self calculateEdgeInset:interfaceOrientation];   
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIEdgeInsets) calculateEdgeInset:(UIInterfaceOrientation)interfaceOrientation {
    
    CGFloat leftInset = CATEGORIES_VIEW_WIDTH - _leftInset;
    CGFloat rightInset = 0.0f;
    
    //left inset depends on interface orientation
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        rightInset = 2 * _pageWidth + _leftInset - self.bounds.size.width;
    }
    
    // return edge inset
    return UIEdgeInsetsMake(0.0f, leftInset, 0.0f, rightInset);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadInvisiblePagesOnStock {
    // get pages on stock
    NSArray* array = [self pagesOnStock];
    
    // get lat index of array
    __block NSUInteger lastIndex = [array count] -1;
    
    // enumerate all pages on stock
    [array enumerateObjectsUsingBlock:^(CLSegmentedView* page, NSUInteger idx, BOOL *stop) {
        // if item is not null and is not last page (first visible page on stock)
        if ((page.isLoaded) && (idx != lastIndex)) {
            // unload page
            [self unloadPage:page remove:NO];
        }
    }];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CLSegmentedView *)createPageFromView:(UIView*)view size:(CLViewSize)viewSize {
    CLSegmentedView *page = [[CLSegmentedView alloc] initWithSize:viewSize];
    page.showRoundedCorners = YES;
    [page setAutoresizingMask:
     UIViewAutoresizingFlexibleLeftMargin |
     UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleBottomMargin |
     UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight];
    page.contentView = view;
    
    return page;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) unloadPage:(CLSegmentedView*)page remove:(BOOL)remove {
    NSUInteger index = [_pages indexOfObject: page];
    
    if (index != NSNotFound) {
        [page removeFromSuperview];
        page.contentView = nil;
        
        // send message to delegate
        [self didUnloadPage:page];        
        
        // check if remove
        if (remove) {
            
            // check if last page is wider page
            if ((index == ([_pages count] -1)) && (_flags.hasWiderPage)) {
                _flags.hasWiderPage = NO;
            }
            
            [_pages removeObject: page];
        }
    }    
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)normalizePageIndex:(NSInteger)index {
    return MAX(0, MIN(index, [_pages count] -1));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize) calculatePageSize:(UIView*)view {
    CLViewSize size = [(CLSegmentedView*)view viewSize];
    CGFloat height = _scrollView.frame.size.height;
    CGFloat width = _pageWidth;
    
    if (size == CLViewSizeWider) {
        width = [self widerPageWidth];
    }

    return CGSizeMake(width, height);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setProperSizesForLoadedPages:(UIInterfaceOrientation)interfaceOrientation {
    [_pages enumerateObjectsUsingBlock:^(CLSegmentedView* page, NSUInteger idx, BOOL *stop) {
        if (page.isLoaded) {
            UIView* view = (UIView*)page;
            CGRect rect = view.frame;
            CGPoint point = [self calculateOriginOfPageAtIndex: idx];
            CGSize size = [self calculatePageSize: page];
            rect.size = size;
            rect.origin = point;
            [view setFrame:rect];
            [view setNeedsLayout];
        }
    }];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat) widerPageWidth {
    return self.frame.size.width - _widerLeftInset;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setProperPositionOfPageAtIndex:(NSInteger)index {

    if ([self pageExistAtIndex: index]) {
        CLSegmentedView* page = [_pages objectAtIndex: index]; 

        if (page.isLoaded) {
            UIView* page = (UIView*)page;
            
            CGRect rect = [page frame];
            rect.origin = [self calculateOriginOfPageAtIndex: index];
            [page setFrame: rect];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint) calculateOriginOfPageAtIndex:(NSInteger)index {
    return CGPointMake(MAX(0, _pageWidth * index), 0.0f);
}

#pragma mark -
#pragma mark UIScrollView delegates methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if(scrollView.dragging && scrollView.tracking && !scrollView.pagingEnabled) {
        [scrollView setPagingEnabled:YES];
    }
    
    if ([_pages count] == 0) return;
    
    // operations connected with Pull To Detach Pages action
    [self sendDetachDelegateMethodsIfNeeded];
    
    // operations connected with Page Did Appear/Disappear delegate metgods
    [self sendAppearanceDelegateMethodsIfNeeded];

    if (_flags.isDetachPages) return;
    
    // calculate first visible page
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];

    // bug fix with bad position of first page
    if ((firstVisiblePageIndex == 0) && (-_scrollView.contentOffset.x >= _scrollView.contentInset.left)) {
        // get page at index
        CLSegmentedView* page = [_pages objectAtIndex: firstVisiblePageIndex];
        if (page.isLoaded) {
            CGRect rect = [page frame];
            rect.origin.x = 0;
            [page setFrame:rect];
        }
    }
    
    [self loadBoundaryPagesIfNeeded];    
    
    // operations connected with blocking pages on stock
    for (NSInteger i=0; i<=firstVisiblePageIndex; i++) {
        
        // check if page index is in bounds 
        if ([self pageExistAtIndex: i]) {
            // get page at index
            CLSegmentedView* page = [_pages objectAtIndex: i];

            if (i == firstVisiblePageIndex) {

                CGFloat contentOffset = _scrollView.contentOffset.x;
                
                if (((i == 0) && (contentOffset <= 0)) || ([_pages count] == 1)) {
                    return;
                }
                
                UIView* view = (UIView*)page;

                CGRect rect = [view frame];
                rect.origin.x = contentOffset;
                [view setFrame: rect];
                
            } else {
                if (page.isLoaded) {
                    [self unloadPage:page remove:NO];
                }
                
            }
        }
    }

}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

/////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
//    [scrollView setPagingEnabled:NO];
//}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_flags.isDetachPages) _flags.isDetachPages = NO;

    #ifdef CONTESTED_CASE
    [_scrollView setPagingEnabled: NO];
    #endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [_scrollView setPagingEnabled: YES];
    [_scrollView setPagingEnabled: NO];
    [_scrollView setScrollEnabled: YES];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

    if (!_pullToDetachPages) return;
    
    CGFloat realContentOffsetX = _scrollView.contentOffset.x + _scrollView.contentInset.left;

    if ((_flags.willDetachPages) && (realContentOffsetX < - _scrollView.frame.size.width * PULL_TO_DETACH_FACTOR)) {
        [self didPullToDetachPages];
    }

    if ((_flags.willDetachPages) && (realContentOffsetX > - _scrollView.frame.size.width * PULL_TO_DETACH_FACTOR)) {
        [self didCancelPullToDetachPages];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {

    NSInteger secondVisiblePageIndex = [self indexOfFirstVisiblePage] + 1;
    [self setProperPositionOfPageAtIndex: secondVisiblePageIndex];
}

#pragma mark -
#pragma mark Delegate methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didLoadPage:(UIView*)page {
    if ([_delegate respondsToSelector:@selector(cascadeView:didLoadPage:)]) {
        [_delegate cascadeView:self didLoadPage:page];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didAddPage:(UIView*)page animated:(BOOL)animated {
    if ([_delegate respondsToSelector:@selector(cascadeView:didAddPage:animated:)]) {
        [_delegate cascadeView:self didAddPage:page animated:YES];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didPopPageAtIndex:(NSInteger)index {
    if ([_delegate respondsToSelector:@selector(cascadeView:didPopPageAtIndex:)]) {
        [_delegate cascadeView:self didPopPageAtIndex:index];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didUnloadPage:(UIView*)page {
    if ([_delegate respondsToSelector:@selector(cascadeView:didUnloadPage:)]) {
        [_delegate cascadeView:self didUnloadPage:page];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageDidAppearAtIndex:(NSInteger)index {
    if (![self pageExistAtIndex: index]) return;

//    NSInteger secondVisiblePageIndex = [self indexOfFirstVisiblePage] +1;
//    [self setProperPositionOfPageAtIndex: secondVisiblePageIndex];

    if ([_delegate respondsToSelector:@selector(cascadeView:pageDidAppearAtIndex:)]) {
        [_delegate cascadeView:self pageDidAppearAtIndex:index];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) pageDidDisappearAtIndex:(NSInteger)index {
    if (![self pageExistAtIndex: index]) return;

    if ([_delegate respondsToSelector:@selector(cascadeView:pageDidDisappearAtIndex:)]) {
        [_delegate cascadeView:self pageDidDisappearAtIndex:index];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didStartPullingToDetachPages {
    _flags.willDetachPages = YES;
    if ([_delegate respondsToSelector:@selector(cascadeViewDidStartPullingToDetachPages:)]) {
        [_delegate cascadeViewDidStartPullingToDetachPages:self];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didPullToDetachPages {
    _flags.willDetachPages = NO;
    _flags.isDetachPages = YES;
    if ([_delegate respondsToSelector:@selector(cascadeViewDidPullToDetachPages:)]) {
        [_delegate cascadeViewDidPullToDetachPages:self];
    }

    [self performSelector:@selector(setProperContentSize) withObject:nil afterDelay:0.3];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) didCancelPullToDetachPages {
    _flags.willDetachPages = NO;
    if ([_delegate respondsToSelector:@selector(cascadeViewDidCancelPullToDetachPages:)]) {
        [_delegate cascadeViewDidCancelPullToDetachPages:self];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) sendAppearanceDelegateMethodsIfNeeded {
    // calculate first visible page
    NSInteger firstVisiblePageIndex = [self indexOfFirstVisiblePage];
    
    if (_indexOfFirstVisiblePage > firstVisiblePageIndex) {
        [self pageDidAppearAtIndex: firstVisiblePageIndex];
        _indexOfFirstVisiblePage = firstVisiblePageIndex;
    }
    else if (_indexOfFirstVisiblePage < firstVisiblePageIndex) {
        [self pageDidDisappearAtIndex: _indexOfFirstVisiblePage];
        _indexOfFirstVisiblePage = firstVisiblePageIndex;
    }
    
    // calculate last visible page
    NSInteger lastVisiblePageIndex = [self indexOfLastVisibleView: NO];
    
    if (_indexOfLastVisiblePage < lastVisiblePageIndex) {
        [self pageDidAppearAtIndex: lastVisiblePageIndex];
        _indexOfLastVisiblePage = lastVisiblePageIndex;
    }
    else if (_indexOfLastVisiblePage > lastVisiblePageIndex) {
        [self pageDidDisappearAtIndex: _indexOfLastVisiblePage];
        _indexOfLastVisiblePage = lastVisiblePageIndex;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) sendDetachDelegateMethodsIfNeeded {
    CGFloat realContentOffsetX = _scrollView.contentOffset.x + _scrollView.contentInset.left;
    
    if ((_pullToDetachPages) && (!_flags.isDetachPages)) {
        if ((!_flags.willDetachPages) && (realContentOffsetX < - _scrollView.frame.size.width * PULL_TO_DETACH_FACTOR)) {
            [self didStartPullingToDetachPages];
        }
        
        if ((_flags.willDetachPages) && (realContentOffsetX > - _scrollView.frame.size.width * PULL_TO_DETACH_FACTOR)) {
            [self didCancelPullToDetachPages];
        }
    }
}

#pragma mark -
#pragma mark Setters

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void) setLeftInset:(CGFloat)newLeftInset {
    CGFloat width = [UIScreen mainScreen].bounds.size.height;
    
    _leftInset = newLeftInset;
    _pageWidth = (width - _leftInset) / 2.0f;
    
    // by @dodikk
    if (_pageWidth == 0.0f ) {
        NSAssert(NO, @"CLCascadeView->_pageWidth == 0. Possible zero division crashes");
    }
    
    _scrollView.frame = CGRectMake(_leftInset, 0.0, _pageWidth, self.frame.size.height);
    
    [self setProperEdgeInset: NO];
}

@end
