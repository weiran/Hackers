//
//  WZActivityViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZActivityViewController.h"

#import "TUSafariActivity/TUSafariActivity.h"
#import <ARChromeActivity/ARChromeActivity.h>
#import <ARKippsterActivity/ARKippsteractivity.h>
#import "WZInstapaperActivity.h"
#import "WZPinboardActivity.h"
#import "WZPocketActivity.h"
#import "WZReadabilityActivity.h"
#import "NNNetwork/NNNetwork.h"
#import "NNNetwork/NNOAuth1Credential.h"
#import "WZNotify.h"

@interface WZActivityViewController () <NNReadLaterActivityDelegate> {
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

@implementation WZActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // gesture recognizer to dismiss UIActivityView when tapped outside
    if (!IS_IPAD()) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(tapOut:)];
        _tapGestureRecognizer.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:_tapGestureRecognizer];
    }
}

- (void)viewWillUnload {
    if (!IS_IPAD()) {
        [self.view removeGestureRecognizer:_tapGestureRecognizer];
    }
}

- (void)tapOut:(id)sender {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    CGPoint point = [tapGestureRecognizer locationInView:self.view];
    
    CGFloat tappableHeight = 0;
    
    for (UIView *view in [self.view.subviews[0] subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            tappableHeight = view.frame.origin.y;
        }
    }
        
    if (point.y <= tappableHeight) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

+ (WZActivityViewController *)activityViewControllerWithUrl:(NSURL *)url text:(NSString *)text {
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    WZInstapaperActivity *instapaperActivity = [[WZInstapaperActivity alloc] init];
    WZPinboardActivity *pinboardActivity = [[WZPinboardActivity alloc] init];
    ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];
    chromeActivity.activityTitle = @"Open in Chrome";
    ARKippsterActivity *kippsterActivity = [[ARKippsterActivity alloc] init];
    kippsterActivity.activityTitle = @"Send to Kippster";
    WZPocketActivity *pocketActivity = [[WZPocketActivity alloc] init];
    WZReadabilityActivity *readabilityActivity = [[WZReadabilityActivity alloc] init];
    
    NSArray *activities = @[safariActivity, chromeActivity, instapaperActivity, pinboardActivity, pocketActivity, readabilityActivity, kippsterActivity];
    NSArray *activityItems = @[text, url];
    
    WZActivityViewController *activityViewController = [[WZActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    activityViewController.url = url;
    [activityViewController setValue:text forKey:@"subject"];

    return activityViewController;
}

@end
