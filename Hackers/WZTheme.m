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
    if (!theme) {
        [defaults setValue:kSettingsThemeLight forKey:kSettingsTheme];
        [defaults synchronize];
        return YES;
    }
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
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                               UITextAttributeTextColor : [UIColor colorWithWhite:0.87 alpha:1.0],
                        UITextAttributeTextShadowColor  : [UIColor clearColor]
     }
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithWhite:0.5 alpha:1.0]];
}

+ (void)setDarkTheme {
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
        if (!darkTitleTextColor) darkTitleTextColor = [UIColor colorWithWhite:0.7 alpha:1.0];
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
        return [UIColor colorWithWhite:0.5 alpha:1.0];
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

+ (UIColor *)mainTextColorInverted {
    if ([self lightTheme]) {
        return [UIColor colorWithWhite:1 alpha:1.0];
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0 alpha:1.0];
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
//        if (!darkBackgroundColor) darkBackgroundColor = [UIColor colorWithWhite:0.13 alpha:1.0];
        if (!darkBackgroundColor) darkBackgroundColor = [UIColor blackColor];
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
//        return [UIColor colorWithWhite:0.1 alpha:1.0];
        return [UIColor colorWithWhite:0.14 alpha:1.0];
    }
}


+ (UIColor *)navigationColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.97 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.1 alpha:1.0];
        return color;
    }
}

+ (UIColor *)segmentBackgroundColor {
    if ([self lightTheme]) {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.6 alpha:1];
        return color;
    } else {
        static UIColor *color = nil;
        if (!color) color = [UIColor colorWithWhite:0.3 alpha:1];
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

+ (UIColor *)menuBackgroundColor {
    static UIColor *color = nil;
    if (!color) color = [UIColor colorWithWhite:0.12 alpha:1];
    return color;
}


+ (UIColor *)menuSeparatorColor {
    static UIColor *color = nil;
    if (!color) color = [UIColor colorWithWhite:0.14 alpha:1.0];
    return color;
}

+ (UIColor *)menuTitleColor {
    static UIColor *color = nil;
    if (!color) color = [UIColor colorWithWhite:0.7 alpha:1.0];
    return color;
}
@end
