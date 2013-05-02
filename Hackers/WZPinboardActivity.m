//
//  WZPinboardActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZPinboardActivity.h"
#import "WZHackersDataAPI.h"
#import "WZAccountManager.h"

@interface WZPinboardActivity ()
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *title;
@end

@implementation WZPinboardActivity

- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
	return @"Send to Pinboard";
}


- (UIImage *)activityImage {
    return [UIImage imageNamed:@"pinboard-icon"];
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
		} else if ([activityItem isKindOfClass:[NSString class]]) {
            _title = activityItem;
        }
	}
}

- (void)performActivity {
    [[WZAccountManager shared] sendURL:_URL.absoluteString title:_title toService:kSettingsPinboard];
    [self activityDidFinish:YES];
}

@end
