//
//  WZNavigationController.h
//  Hackers
//
//  Created by Weiran Zhang on 28/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WZMainViewController.h"

@interface WZNavigationController : UINavigationController

@property (nonatomic, assign) BOOL allowsRotation;
@property (nonatomic, readonly) UILabel *titleLabel;
- (void)setNewsType:(WZNewsType)newsType;

@end
