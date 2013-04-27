//
//  WZDefaults.h
//  Hackers
//
//  Created by Weiran Zhang on 07/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTitleFontName @"HelveticaNeue"
#define kTitleFontSize 15

#define kBodyFontName @"HelveticaNeue-Light"
#define kBodyFontSize 14

#define kNavigationFontName @"HelveticaNeue-Light"
#define kNavigationFontSize 20

#define kBackgroundColorLight [UIColor colorWithWhite:0.95 alpha:1]

// NSUserDefault keys

#define kSettingsInstapaper @"Instapaper"
#define kSettingsInstapaperEnabled @"EnableInstapaper"
#define kSettingsInstapaperUsername @"InstapaperUsername"
#define kSettingsInstapaperPassword @"InstapaperPassword"

@class WZAppDelegate;

@interface WZDefaults : NSObject

+ (WZAppDelegate *)appDelegate;
+ (BOOL)getBoolKey:(NSString *)key;

@end
