//
//  WZInstapaperActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZInstapaperActivity.h"
#import "WZHackersDataAPI.h"
#import "WZAccountManager.h"

#import <MBProgressHUD.h>

@interface WZInstapaperActivity ()
@property (nonatomic, strong) NSURL *URL;
@end

@implementation WZInstapaperActivity


- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
	return @"Send to Instapaper";
}


- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNInstapaperActivity~iphone"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			_URL = activityItem;
		}
	}
}

- (void)performActivity {
    [[WZAccountManager shared] sendURL:_URL.absoluteString toService:kSettingsInstapaper];
    [self activityDidFinish:YES];
}



@end
