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

@class WZAppDelegate;

@interface WZDefaults : NSObject

+ (WZAppDelegate *)appDelegate;

@end
