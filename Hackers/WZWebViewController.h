//
//  WZWebViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 13/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WZWebViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (id)initWithURL:(NSURL *)url;
- (void)loadURL:(NSURL *)url;

@end
