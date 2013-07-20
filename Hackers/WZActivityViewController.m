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
#import "WZInstapaperActivity.h"
#import "WZPinboardActivity.h"

@interface WZActivityViewController () {
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

@implementation WZActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // gesture recognizer to dismiss UIActivityView when tapped outside
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(tapOut:)];
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_tapGestureRecognizer];
}

- (void)viewWillUnload {
    [self.view removeGestureRecognizer:_tapGestureRecognizer];
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
    NSArray *activities = @[safariActivity, chromeActivity, instapaperActivity, pinboardActivity];
    NSArray *activityItems = @[text, url];
    
    WZActivityViewController *activityViewController = [[WZActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    
    return activityViewController;
}

@end
