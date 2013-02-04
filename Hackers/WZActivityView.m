//
//  WZActivityView.m
//  Hackers
//
//  Created by Weiran Zhang on 02/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZActivityView.h"

#import <NNNetwork/NNNetwork.h>
#import <TUSafariActivity/TUSafariActivity.h>

@implementation WZActivityView

+ (UIActivityViewController *)activitViewControllerWithUrl:(NSURL *)url text:(NSString *)text {

    NNInstapaperActivity *instapaperActivity = [[NNInstapaperActivity alloc] init];
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    NSArray *activities = @[safariActivity, instapaperActivity];
    NSArray *activityItems = @[url, text];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    
    return activityViewController;
}

@end
