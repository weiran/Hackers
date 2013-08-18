//
//  WZReadabilityActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZReadabilityActivity.h"

#import "WZActivityManager.h"

@implementation WZReadabilityActivity

- (NSString *)activityTitle {
	return @"Send to Readability";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNReadabilityActivity"];
}

- (void)performActivity {
    WZActivityManager *activityManager = [[WZActivityManager alloc] init];
    [activityManager sendURL:self.URLArray[0] toService:kSettingsReadability];
    [self activityDidFinish:YES];
}
@end
