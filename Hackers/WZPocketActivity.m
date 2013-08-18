//
//  WZPocketActivity.m
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZPocketActivity.h"

#import "WZActivityManager.h"

@implementation WZPocketActivity

- (NSString *)activityTitle {
	return @"Send to Pocket";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"NNPocketActivity"];
}

- (void)performActivity {
    WZActivityManager *activityManager = [[WZActivityManager alloc] init];
    [activityManager sendURL:self.URLArray[0] toService:kSettingsPocket];
    [self activityDidFinish:YES];
}

@end
