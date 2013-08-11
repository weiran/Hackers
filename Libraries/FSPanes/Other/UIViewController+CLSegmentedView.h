//
//  UIViewController+CLSegmentedView.h
//  Cascade
//
//  Created by Emil Wojtaszek on 11-05-07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLSegmentedView.h"

@interface UIViewController (UIViewController_CLSegmentedView)

@property (nonatomic, retain, readonly) UIView* headerView;
@property (nonatomic, retain, readonly) UIView* footerView;
@property (nonatomic, retain, readonly) UIView* contentView;

@property (nonatomic, retain) CLSegmentedView* segmentedView;

@end
