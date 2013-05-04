//
//  WZTheme.m
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZTheme.h"
#import "WZNavigationController.h"

@implementation WZTheme

+ (bool)darkTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *theme = [defaults stringForKey:kSettingsTheme];
    return [theme isEqualToString:kSettingsThemeDark];
}

+ (bool)lightTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *theme = [defaults stringForKey:kSettingsTheme];
    return [theme isEqualToString:kSettingsThemeLight];
}

+ (void)defaults {
    if ([self lightTheme]) {
        [self setLightTheme];
    } else {
        [self setDarkTheme];
    }
}

+ (void)setLightTheme {
//    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:0.87 alpha:1]];
//    [[UIToolbar appearance] setTintColor:[UIColor colorWithWhite:0.87 alpha:1]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{
//                                    UITextAttributeFont : [UIFont fontWithName:kNavigationFontName size:kNavigationFontSize],
//                               UITextAttributeTextColor : [UIColor blackColor],
//                        UITextAttributeTextShadowColor  : [UIColor clearColor]
//     }];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar-bg.png"] forBarMetrics:UIBarMetricsDefault];
//    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar-bg.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                               UITextAttributeTextColor : [UIColor colorWithWhite:0.87 alpha:1.0],
                        UITextAttributeTextShadowColor  : [UIColor clearColor]
     }
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
}

+ (void)setDarkTheme {
//    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:0.13 alpha:1]];
//    [[UIToolbar appearance] setTintColor:[UIColor colorWithWhite:0.13 alpha:1]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{
//                                    UITextAttributeFont : [UIFont fontWithName:kNavigationFontName size:kNavigationFontSize],
//                               UITextAttributeTextColor : [UIColor colorWithWhite:0.87 alpha:1.0],
//                        UITextAttributeTextShadowColor  : [UIColor clearColor]
//     }];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar-bg-dark.png"] forBarMetrics:UIBarMetricsDefault];
//    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar-bg-dark.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                               UITextAttributeTextColor : [UIColor colorWithWhite:0.87 alpha:1.0],
                        UITextAttributeTextShadowColor  : [UIColor clearColor]
     }
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
}

+ (void)updateNavigationBar:(WZNavigationController *)navigation {
//    navigation.titleLabel.textColor = [self titleTextColor];
    navigation.navigationItem.title = @"Test";
    [navigation.navigationBar setNeedsDisplay];
}

+ (UIColor *)titleTextColor {
    if ([self lightTheme]) {
        static UIColor *lightTitleTextColor = nil;
        if (!lightTitleTextColor) lightTitleTextColor = [UIColor blackColor];
        return lightTitleTextColor;
    } else {
        static UIColor *darkTitleTextColor = nil;
        if (!darkTitleTextColor) darkTitleTextColor = [UIColor colorWithWhite:0.77 alpha:1.0];
        return darkTitleTextColor;
    }
}

+ (UIColor *)subtitleTextColor {
    if ([self lightTheme]) {
        static UIColor *lightSubtitleTextColor = nil;
        if (!lightSubtitleTextColor) lightSubtitleTextColor = [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
        return lightSubtitleTextColor;
    } else {
        static UIColor *darkSubtitleTextColor = nil;
        if (!darkSubtitleTextColor) darkSubtitleTextColor = [UIColor colorWithRed:123.0/255.0 green:136.0/255.0 blue:201.0/255.0 alpha:1.0];
        return darkSubtitleTextColor;
    }
}

+ (UIColor *)detailTextColor {
    if ([self lightTheme]) {
        return [UIColor lightGrayColor];
    } else {
        return [UIColor lightGrayColor];
    }
}

+ (UIColor *)mainTextColor {
    if ([self lightTheme]) {
        return [UIColor blackColor];
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.77 alpha:1.0];
        return color;
    }
}

+ (UIColor *)userTextColor {
    if ([self lightTheme]) {
        static UIColor *lightUserTextColor = nil;
        if (!lightUserTextColor) lightUserTextColor = [UIColor colorWithRed:128.0/255.0 green:42.0/255.0 blue:0.0/255.0 alpha:1.0];
        return lightUserTextColor;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithRed:201.0/255.0 green:64.0/255.0 blue:60.0/255.0 alpha:1.0];
        return color;
    }
}

+ (UIColor *)backgroundColor {
    if ([self lightTheme]) {
        static UIColor *lightBackgroundColor = nil;
        if (!lightBackgroundColor) lightBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        return lightBackgroundColor;
    } else {
        static UIColor *darkBackgroundColor = nil;
        if (!darkBackgroundColor) darkBackgroundColor = [UIColor colorWithWhite:0.13 alpha:1.0];
        return darkBackgroundColor;
    }
}

+ (UIColor *)highlightedBackgroundColor {
    if ([self lightTheme]) {
        static UIColor *lightBackgroundColor = nil;
        if (!lightBackgroundColor) lightBackgroundColor = [UIColor colorWithWhite:0.87 alpha:1.0];
        return lightBackgroundColor;
    } else {
        static UIColor *lightBackgroundColor = nil;
        if (!lightBackgroundColor) lightBackgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        return lightBackgroundColor;
    }
}

+ (UIColor *)lightBackgroundColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:1.0 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.2 alpha:1];
        return color;
    }
}

+ (UIColor *)separatorColor {
    if ([self lightTheme]) {
        return [UIColor colorWithWhite:0.83 alpha:1.0];
    } else {
        return [UIColor darkGrayColor];
    }
}

+ (UIColor *)navigationColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.97 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha: 1];
        return color;
    }
}

+ (UIColor *)segmentBackgroundColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.95 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.3 alpha:1];
        return color;
    }
}

+ (UIColor *)segmentSelectedBackgroundColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.82 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.0 alpha:1];
        return color;
    }
}

+ (UIColor *)buttonTitleShadowColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor whiteColor];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.5 alpha:1];
        return color;
    }
}

@end
