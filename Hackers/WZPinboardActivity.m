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

- (void)performActivity {
    [[WZAccountManager shared] sendURL:self.URL.absoluteString title:self.title toService:kSettingsPinboard];
    [self activityDidFinish:YES];
}

@end
