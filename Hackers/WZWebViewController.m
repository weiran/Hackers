//
//  WZWebViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 13/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZWebViewController.h"

//#import "WZWebView.h"

@interface WZWebViewController ()
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURL *defaultURL;
@end

@implementation WZWebViewController

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    
    if (self) {
        _defaultURL = url;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutNavigationBar];
    [self setupWebView];
}

- (void)setupWebView {
    //_webView = [[WZWebView alloc] initWithFrame:self.view.bounds];
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    if (_defaultURL) {
        [self loadURL:_defaultURL];
    }
}

- (void)loadURL:(NSURL *)url {
    //[_webView.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)layoutNavigationBar {
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, 32, 32);
    closeButton.accessibilityLabel = @"Close";
    [closeButton setImage:[UIImage imageNamed:@"x"] forState:UIControlStateNormal];
    
    UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    [self.navigationItem setLeftBarButtonItem:closeBarButton];
}

@end
