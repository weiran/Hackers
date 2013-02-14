//
//  WZWebViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 13/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "WZWebViewController.h"
#import "WZWebView.h"

#define kToolBarHeight 44
#define kToolBarFixedWidth 20
#define kBarButtonIconWidth 28
#define kBarButtonIconHeight 33
#define kMobilizerURL @"http://www.instapaper.com/m?u="

@interface WZWebViewController () {
    
    NSURL *_mobilizedURL;
    NSURL *_currentURL;

}
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *mobilizerBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *reloadBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewTopSpacingConstraint;
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
    [self layoutWebView];
    [self layoutNavigationBar];
    [self layoutToolbar];
}

- (void)layoutNavigationBar {
    if (_navigationBarHidden) {
        _webViewTopSpacingConstraint.constant = 0;
    } else {
        _webViewTopSpacingConstraint.constant = 44;
    }
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, 32, 32);
    closeButton.accessibilityLabel = @"Close";
    [closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:[UIImage imageNamed:@"x"] forState:UIControlStateNormal];
    
    UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    [navigationItem setLeftBarButtonItem:closeBarButton];
    
    [_navigationBar pushNavigationItem:navigationItem animated:NO];
}

- (void)layoutWebView {
    _webView.backgroundColor = [UIColor underPageBackgroundColor];
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    _webView.scrollView.scrollsToTop = NO;
    
    if (_defaultURL) {
        [self loadURL:_defaultURL];
    }
}

- (void)layoutToolbar {
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    backButton.accessibilityLabel = @"Back";
    [backButton setImage:[UIImage imageNamed:@"back-icon"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    forwardButton.accessibilityLabel = @"Forward";
    [forwardButton setImage:[UIImage imageNamed:@"forward-icon"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *mobilizerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mobilizerButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    mobilizerButton.accessibilityLabel = @"Mobilizer";
    [mobilizerButton setImage:[UIImage imageNamed:@"mobilizer-icon"] forState:UIControlStateNormal];
    [mobilizerButton setImage:[UIImage imageNamed:@"mobilizer-icon-highlighted"] forState:UIControlStateSelected];
    [mobilizerButton addTarget:self action:@selector(mobilizerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    reloadButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    reloadButton.accessibilityLabel = @"Reload";
    reloadButton.enabled = NO;
    [reloadButton setImage:[UIImage imageNamed:@"refresh-icon"] forState:UIControlStateNormal];
    [reloadButton addTarget:self action:@selector(reloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = kToolBarFixedWidth;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    _backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardButton];
    _mobilizerBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mobilizerButton];
    _reloadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reloadButton];
    
    _backBarButtonItem.enabled = NO;
    _forwardBarButtonItem.enabled = NO;
    _mobilizerBarButtonItem.enabled = YES;
    _reloadBarButtonItem.enabled = YES;
    
    NSArray *toolbarItems = @[_backBarButtonItem, fixedSpace, _forwardBarButtonItem, flexibleSpace, _mobilizerBarButtonItem, fixedSpace, _reloadBarButtonItem];
    
    [_toolbar setItems:toolbarItems animated:YES];
}

#pragma mark - Navigation Bar Buttons

- (void)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Toolbar Buttons

- (void)backButtonPressed:(id)sender {
    [_webView goBack];
    [self updateButtonsEnabled];
}

- (void)forwardButtonPressed:(id)sender {
    [_webView goForward];
    [self updateButtonsEnabled];
}

- (void)reloadButtonPressed:(id)sender {
    [_webView reload];
    [self updateButtonsEnabled];
}

- (void)updateButtonsEnabled {
    _backBarButtonItem.enabled = [_webView canGoBack];
    _forwardBarButtonItem.enabled = [_webView canGoForward];
}

- (void)mobilizerButtonPressed:(id)sender {
    UIButton *mobilizerButton = (UIButton *)sender;
    NSString *mobilizerURLString = kMobilizerURL;
    
    NSURL *requestURL;
    
    if ([_currentURL.absoluteString hasPrefix:mobilizerURLString]) {
        requestURL = _mobilizedURL;
        [mobilizerButton setSelected:NO];
    } else if (!_currentURL || [_currentURL.absoluteString isEqualToString:@""]) {
        return;
    } else {
        _mobilizedURL = _webView.request.URL;
        NSString *encodedURLString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)_currentURL.absoluteString, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
        NSString *mobilizerURL = [NSString stringWithFormat:[mobilizerURLString stringByAppendingString:@"%@"], encodedURLString];
        requestURL = [NSURL URLWithString:mobilizerURL];
        [mobilizerButton setSelected:YES];
        
        [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [_webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateButtonsEnabled];
    _currentURL = webView.request.URL;
    self.navigationBar.topItem.title = webView.request.URL.absoluteString;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [MBProgressHUD hideHUDForView:self.webView animated:YES];
    [self updateButtonsEnabled];
    _currentURL = webView.request.URL;
    self.navigationBar.topItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [MBProgressHUD hideHUDForView:self.webView animated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error loading page"
                                                    message:error.localizedDescription
                                                   delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] hasPrefix:@"sms:"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
		if ([[request.URL absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
			[[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
			[[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"]) {
			[[UIApplication sharedApplication] openURL:request.URL];
			return NO;
		}
	}
    
    return YES;
}


- (void)loadURL:(NSURL *)url {
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}


@end
