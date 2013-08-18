//
//  WZReadabilityActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZReadabilityActivity.h"

#import "WZActivityManager.h"

@interface WZReadabilityActivity ()
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSString *title;
@end

@implementation WZReadabilityActivity

- (NSString *)activityTitle {
	return @"Send to Readability";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNReadabilityActivity"];
}

- (void)performActivity {
    WZActivityManager *activityManager = [[WZActivityManager alloc] init];
    [activityManager sendURL:self.URL toService:kSettingsReadability];
    [self activityDidFinish:YES];
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
