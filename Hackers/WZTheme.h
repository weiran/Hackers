//
//  WZTheme.h
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZTheme : NSObject

+ (void)defaults;

+ (bool)lightTheme;
+ (bool)darkTheme;

+ (UIColor *)titleTextColor;
+ (UIColor *)subtitleTextColor;
+ (UIColor *)detailTextColor;
+ (UIColor *)mainTextColor;
+ (UIColor *)userTextColor;

+ (UIColor *)backgroundColor;
+ (UIColor *)highlightedBackgroundColor;
+ (UIColor *)lightBackgroundColor;

+ (UIColor *)separatorColor;
+ (UIColor *)navigationColor;

+ (UIColor *)segmentBackgroundColor;
+ (UIColor *)segmentSelectedBackgroundColor;

+ (UIColor *)buttonTitleShadowColor;

+ (void)updateNavigationBar:(UINavigationBar *)navigation;

@end
