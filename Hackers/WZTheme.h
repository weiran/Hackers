//
//  WZTheme.h
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WZNavigationController;

@interface WZTheme : NSObject

+ (void)defaults;

+ (bool)lightTheme;
+ (bool)darkTheme;

+ (UIColor *)titleTextColor;
+ (UIColor *)subtitleTextColor;
+ (UIColor *)detailTextColor;
+ (UIColor *)mainTextColor;
+ (UIColor *)mainTextColorInverted;
+ (UIColor *)userTextColor;

+ (UIColor *)backgroundColor;
+ (UIColor *)highlightedBackgroundColor;
+ (UIColor *)lightBackgroundColor;

+ (UIColor *)separatorColor;
+ (UIColor *)navigationColor;

+ (UIColor *)segmentBackgroundColor;

+ (UIColor *)buttonTitleShadowColor;

+ (UIColor *)menuBackgroundColor;
+ (UIColor *)menuSeparatorColor;
+ (UIColor *)menuTitleColor;

+ (void)updateNavigationBar:(WZNavigationController *)navigation;

@end
