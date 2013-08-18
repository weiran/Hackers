//
//  WZPocketActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZPocketActivity.h"

#import "WZActivityManager.h"

@interface WZPocketActivity ()
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSString *title;
@end

@implementation WZPocketActivity

- (NSString *)activityTitle {
	return @"Send to Pocket";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNPocketActivity"];
}

- (void)performActivity {
    WZActivityManager *activityManager = [[WZActivityManager alloc] init];
    [activityManager sendURL:self.URL toService:kSettingsPocket];
    [self activityDidFinish:YES];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id object in activityItems) {
        if ([object isKindOfClass:[NSURL class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			self.URL = activityItem;
		} else if ([activityItem isKindOfClass:[NSString class]]) {
            self.title = activityItem;
        }
	}
}


@end
