//
//  WZDefaults.h
//  Hackers
//
//  Created by Weiran Zhang on 07/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef UI_USER_INTERFACE_IDIOM()
#define IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#else
#define IS_IPAD() (false)
#endif

#define kTitleFontName @"HelveticaNeue"
#define kTitleFontSize IS_IPAD() ? 18 : 15

#define kBodyFontName @"HelveticaNeue-Light"
#define kBodyFontSize IS_IPAD() ? 17 : 14

#define kNavigationFontName @"HelveticaNeue-Light"
#define kNavigationFontSize 20

#define kBackgroundColorLight [UIColor colorWithWhite:0.95 alpha:1]

// NSUserDefault keys

#define kSettingsInstapaper @"Instapaper"
#define kSettingsInstapaperEnabled @"EnableInstapaper"
#define kSettingsInstapaperUsername @"InstapaperUsername"
#define kSettingsInstapaperPassword @"InstapaperPassword"

#define kSettingsPinboard @"Pinboard"
#define kSettingsPinboardEnabled @"EnablePinboard"
#define kSettingsPinboardUsername @"PinboardUsername"
#define kSettingsPinboardPassword @"PinboardPassword"

#define kSettingsDefaultReadingView @"DefaultReadingView"
#define kSettingsDefaultReadingViewComments @"comments"
#define kSettingsDefaultReadingViewLink @"link"
#define kSettingsPreloadLink @"PreloadLink"

#define kSettingsTheme @"Theme"
#define kSettingsThemeLight @"light"
#define kSettingsThemeDark @"dark"

@class WZAppDelegate;

@interface WZDefaults : NSObject

+ (WZAppDelegate *)appDelegate;

@end
