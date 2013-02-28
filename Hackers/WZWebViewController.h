//
//  WZWebViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 13/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define WZWebViewControllerDismissed @"WZWebViewControllerDismissed"
#define WZWebViewControllerSwipeRight @"WZWebViewControllerSwipeRight"

@interface WZWebViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL navigationBarHidden;
@property (nonatomic) BOOL toolbarHidden;
@property (nonatomic) BOOL enabledGestures;

- (id)initWithURL:(NSURL *)url;
- (void)loadURL:(NSURL *)url;

@end
