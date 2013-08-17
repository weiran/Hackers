//
//  WZActivity.m
//  
//
//  Created by Weiran Zhang on 17/08/2013.
//
//

#import "WZActivity.h"

@implementation WZActivity

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
			self.URL = activityItem;
		} else if ([activityItem isKindOfClass:[NSString class]]) {
            self.title = activityItem;
        }
	}
}

@end
