//
//  WZReadabilityActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZReadabilityActivity.h"

#import "WZAccountManager.h"

@implementation WZReadabilityActivity


- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
	return @"Send to Instapaper";
}


- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNInstapaperActivity"];
}

- (void)performActivity {
    [[WZAccountManager shared] sendURL:self.URL.absoluteString toService:kSettingsInstapaper];
    [self activityDidFinish:YES];
}


@end
