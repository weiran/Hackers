//
//  WZInstapaperActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZInstapaperActivity.h"
#import "WZHackersDataAPI.h"
#import "WZActivityManager.h"


@implementation WZInstapaperActivity


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
    WZActivityManager *activityManager = [[WZActivityManager alloc] init];
    [activityManager sendURL:self.URL toService:kSettingsInstapaper];
    [self activityDidFinish:YES];
}



@end
