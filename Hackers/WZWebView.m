//
//  WZWebView.m
//  Hackers
//
//  Created by Weiran Zhang on 03/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZWebView.h"

#import <QuartzCore/QuartzCore.h>

#define kToolBarHeight 44
#define kToolBarFixedWidth 20
#define kBarButtonIconWidth 28
#define kBarButtonIconHeight 33

@interface WZWebView ()
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *reloadBarButtonItem;
@end

@implementation WZWebView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _webView = [[UIWebView alloc] init];
    _webView.backgroundColor = [UIColor underPageBackgroundColor];
    _webView.delegate = self;
    _webView.scalesPageToFit = YES;
    _webView.scrollView.scrollsToTop = NO;
    [self addSubview:_webView];
    
    [self layoutToolbar];
}

- (void)layoutToolbar {
    if (!_toolbar) {
        CGRect webViewFrame = self.frame;
        CGRect webViewNewFrame = CGRectMake(0, 0, webViewFrame.size.width, webViewFrame.size.height - kToolBarHeight);
        _webView.frame = webViewNewFrame;
        
        CGRect toolbarFrame = CGRectMake(0, webViewFrame.size.height - 44, webViewFrame.size.width, kToolBarHeight);
        _toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
        _toolbar.layer.shadowOpacity = 0;        
        
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
        _reloadBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:reloadButton];
        
        _backBarButtonItem.enabled = NO;
        _forwardBarButtonItem.enabled = NO;
        _reloadBarButtonItem.enabled = YES;

        NSArray *toolbarItems = @[_backBarButtonItem, fixedSpace, _forwardBarButtonItem, flexibleSpace, _reloadBarButtonItem];
        
        [_toolbar setItems:toolbarItems animated:YES];
        
        [self addSubview:_toolbar];
    }
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

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateButtonsEnabled];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateButtonsEnabled];    
}

@end
