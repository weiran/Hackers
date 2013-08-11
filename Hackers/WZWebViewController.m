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
#import "WZActivityViewController.h"
#import "UIViewController+CLCascade.h"
#import "CLCascadeNavigationController.h"

#define kNavigationBarHeight 44
#define kToolbarBarHeight 44
#define kToolBarHeight 44
#define kToolBarFixedWidth 20
#define kBarButtonIconWidth 33
#define kBarButtonIconHeight 33
#define kMobilizerURL @"http://www.instapaper.com/m?u="
#define kHorizontalContentOffsetTrigger -66

@interface WZWebViewController () {
    NSURL *_mobilizedURL;
    NSURL *_currentURL;
    
    BOOL _navigationBarCurrentlyHidden;
    BOOL _toolbarCurrentlyHidden;
}
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *mobilizerBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *reloadBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewTopSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *webViewBottomSpacingConstraint;
@property (nonatomic, strong) NSURL *defaultURL;
@property (strong, nonatomic) UIPopoverController *activityPopoverController;

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
    
    _navigationBarCurrentlyHidden = _navigationBarHidden;
    _toolbarCurrentlyHidden = _toolbarHidden;
    
    UISwipeGestureRecognizer *closeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(close:)];
    closeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.navigationBar addGestureRecognizer:closeGestureRecognizer];
    
    [self layoutWebView];
    [self layoutWebViewConstraints];
    [self layoutNavigationBar];
    [self layoutToolbar];
    [self setupOrientationNotifications];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _webView.scrollView.scrollsToTop = NO;
    [self removeOrientationNotifications];
    [[NSNotificationCenter defaultCenter] postNotificationName:WZWebViewControllerDismissed object:self];
    [_webView stopLoading];
    _webView.delegate = nil;
}

#pragma mark - Layout

- (void)layoutNavigationBar {
    _navigationBar.hidden = _navigationBarCurrentlyHidden;
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    closeButton.accessibilityLabel = @"Close";
    [closeButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:[UIImage themeImageNamed:@"x"] forState:UIControlStateNormal];
    
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shareButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    shareButton.accessibilityLabel = @"Share";
    [shareButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    [shareButton setImage:[UIImage themeImageNamed:@"share-icon"] forState:UIControlStateNormal];
    
//    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    _activityIndicatorView.hidden = YES;
//    _activityIndicatorView.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
//    [_activityIndicatorView startAnimating];
    
    UIBarButtonItem *closeBarButton = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
//    UIBarButtonItem *activityIndicatorButton = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicatorView];
    
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:@""];
    if (!IS_IPAD()) {
        [navigationItem setLeftBarButtonItem:closeBarButton];
    } else {
        navigationItem.hidesBackButton = YES;
    }
    [navigationItem setRightBarButtonItem:shareBarButton];
    
    [_navigationBar pushNavigationItem:navigationItem animated:NO];
}

- (void)layoutWebView {
    _webView.backgroundColor = [UIColor underPageBackgroundColor];
    _webView.delegate = self;
    _webView.scrollView.delegate = self;
    _webView.scalesPageToFit = YES;
    _webView.scrollView.scrollsToTop = NO;
    
    if (_defaultURL) {
        [self loadURL:_defaultURL];
    }
}

- (void)layoutWebViewConstraints {
    if (_navigationBarCurrentlyHidden) {
        _webViewTopSpacingConstraint.constant = 0;
    } else {
        _webViewTopSpacingConstraint.constant = kNavigationBarHeight;
    }
    
    if (_toolbarCurrentlyHidden) {
        _webViewBottomSpacingConstraint.constant = 0;
    } else {
        _webViewBottomSpacingConstraint.constant = kToolbarBarHeight;
    }
}

- (void)layoutToolbar {
    _toolbar.hidden = _toolbarHidden;
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    backButton.accessibilityLabel = @"Back";
    [backButton setImage:[UIImage themeImageNamed:@"back-icon"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    forwardButton.accessibilityLabel = @"Forward";
    [forwardButton setImage:[UIImage themeImageNamed:@"forward-icon"] forState:UIControlStateNormal];
    [forwardButton addTarget:self action:@selector(forwardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *mobilizerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mobilizerButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    mobilizerButton.accessibilityLabel = @"Mobilizer";
    [mobilizerButton setImage:[UIImage themeImageNamed:@"mobilizer-icon"] forState:UIControlStateNormal];
    [mobilizerButton setImage:[UIImage themeImageNamed:@"mobilizer-icon-highlighted"] forState:UIControlStateSelected];
    [mobilizerButton addTarget:self action:@selector(mobilizerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    reloadButton.frame = CGRectMake(0, 0, kBarButtonIconWidth, kBarButtonIconHeight);
    reloadButton.accessibilityLabel = @"Reload";
    reloadButton.enabled = NO;
    [reloadButton setImage:[UIImage themeImageNamed:@"refresh-icon"] forState:UIControlStateNormal];
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

#pragma mark - Rotation

- (void)setupOrientationNotifications {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

- (void)removeOrientationNotifications {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didRotate:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);

    _navigationBar.hidden = _navigationBarHidden || isLandscape;
    _toolbar.hidden = _toolbarHidden || isLandscape;
    _navigationBarCurrentlyHidden = _navigationBarHidden || isLandscape;
    _toolbarCurrentlyHidden = _toolbarHidden || isLandscape;
    
    [self layoutWebViewConstraints];
}

#pragma mark - Navigation Bar Buttons

- (void)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share:(id)sender {
    WZActivityViewController *activityViewController =
        [WZActivityViewController activityViewControllerWithUrl:_defaultURL
                                                           text:[_webView stringByEvaluatingJavaScriptFromString:@"document.title" ]];
    
    if (IS_IPAD()) {
        self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        UIButton *shareButton = (UIButton *)sender;
        [self.activityPopoverController presentPopoverFromRect:CGRectMake(shareButton.frame.origin.x, shareButton.frame.origin.y, shareButton.frame.size.width / 2, shareButton.frame.size.height / 2)
                                                        inView:self.view
                                      permittedArrowDirections:UIPopoverArrowDirectionUp
                                                      animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
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
    
    [_webView stopLoading];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [_webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateButtonsEnabled];
    _currentURL = webView.request.URL;
    _activityIndicatorView.hidden = NO;
    self.navigationBar.topItem.title = webView.request.URL.absoluteString;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [MBProgressHUD hideHUDForView:self.webView animated:YES];
    [self updateButtonsEnabled];
    _currentURL = webView.request.URL;
    _activityIndicatorView.hidden = YES;
    self.navigationBar.topItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    _activityIndicatorView.hidden = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [MBProgressHUD hideHUDForView:self.webView animated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error loading page"
                                                    message:error.localizedDescription
                                                   delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
        [[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
        [[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"] ||
        [[request.URL absoluteString] hasPrefix:@"https://www.youtube.com/v/"] ||
        [[request.URL absoluteString] hasPrefix:@"https://itunes.apple.com/"] ||
        [[request.URL absoluteString] hasPrefix:@"https://phobos.apple.com/"] ||
        [[request.URL scheme] isEqual:@"mailto"] ||
        [[request.URL scheme] isEqual:@"sms"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}


- (void)loadURL:(NSURL *)url {
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"x: %f, y: %f", scrollView.contentOffset.x, scrollView.contentOffset.y);
    if (scrollView.contentOffset.x <= kHorizontalContentOffsetTrigger && _enabledGestures) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WZWebViewControllerSwipeRight object:nil];
    }
}

@end
