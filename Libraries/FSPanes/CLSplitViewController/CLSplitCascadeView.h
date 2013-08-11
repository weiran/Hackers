//
//  CLSplitCascadeView.h
//  Cascade
//
//  Created by Emil Wojtaszek on 11-03-27.
//  Copyright 2011 CreativeLabs.pl. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLSplitCascadeViewController;


@interface CLSplitCascadeView : UIView {
    // views
    UIView* _categoriesView;
    UIView* _cascadeView;
     
    // background
    UIView*     _backgroundView;

    // divider
    UIView*     _dividerView;
    UIImage*    _verticalDividerImage;
    CGFloat     _dividerWidth;
    
}

@property (nonatomic, strong) IBOutlet CLSplitCascadeViewController* splitCascadeViewController;

/*
 * Divider image - image between categories and cascade view
 */
@property (nonatomic, strong) UIImage* verticalDividerImage;

/*
 * Background view - located under cascade view
 */
@property (nonatomic, strong) UIView* backgroundView;

/*
 * Categories view - located on the left, view containing table view
 */
@property (nonatomic, strong) UIView* categoriesView;

/*
 * Cascade content navigator - located on the right, view containing cascade view controllers
 */
@property (nonatomic, strong) UIView* cascadeView;


@end
