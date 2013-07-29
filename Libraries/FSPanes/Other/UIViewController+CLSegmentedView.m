//
//  UIViewController+CLSegmentedView.m
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIViewController+CLSegmentedView.h"


@implementation UIViewController (UIViewController_CLSegmentedView)

@dynamic segmentedView;
@dynamic headerView;
@dynamic footerView;
@dynamic contentView;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CLSegmentedView*) segmentedView {
    UIView *contentView = [self.view superview];
    return (CLSegmentedView*)[contentView superview];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) headerView {

    if (![self.segmentedView isKindOfClass:[CLSegmentedView class]]) return nil;
    
    CLSegmentedView* view_ = (CLSegmentedView*)self.segmentedView;
    return view_.headerView;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) footerView {

    if (![self.segmentedView isKindOfClass:[CLSegmentedView class]]) return nil;
    
    CLSegmentedView* view_ = (CLSegmentedView*)self.segmentedView;
    return view_.footerView;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*) contentView {
    if (![self.segmentedView isKindOfClass:[CLSegmentedView class]]) return self.view;

    CLSegmentedView* view_ = (CLSegmentedView*)self.segmentedView;
    return view_.contentView;
}

@end
