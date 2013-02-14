//
//  WZActivityViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZActivityViewController.h"

#import <TUSafariActivity/TUSafariActivity.h>

@implementation WZActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // gesture recognizer to dismiss UIActivityView when tapped outside
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(tapOut:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)tapOut:(id)sender {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    CGPoint point = [tapGestureRecognizer locationInView:self.view];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat tappableHeight = screenBounds.size.height - self.view.frame.size.height;
    
    if (point.y <= tappableHeight) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

+ (WZActivityViewController *)activityViewControllerWithUrl:(NSURL *)url text:(NSString *)text {
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    NSArray *activities = @[safariActivity];
    NSArray *activityItems = @[url, text];
    
    WZActivityViewController *activityViewController = [[WZActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    
    return activityViewController;
}

@end
