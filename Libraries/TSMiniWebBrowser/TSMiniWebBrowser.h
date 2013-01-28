//
//  TSMiniWebBrowser.h
//  TSMiniWebBrowserDemo
//
//  Created by Toni Sala Echaurren on 18/01/12.
//  Copyright 2012 Toni Sala. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>

@protocol TSMiniWebBrowserDelegate <NSObject>
@optional
-(void) tsMiniWebBrowserDidDismiss;
@end

typedef enum {
	TSMiniWebBrowserModeNavigation,
	TSMiniWebBrowserModeModal,
    TSMiniWebBrowserModeTabBar,
} TSMiniWebBrowserMode;

@interface TSMiniWebBrowser : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
    // URL
    NSURL *urlToLoad;
    
    // Layout
    UIWebView *webView;
    UIToolbar *toolBar;
    UINavigationBar *navigationBarModal; // Only used in modal mode
    
    // Toolbar items
    UIActivityIndicatorView *activityIndicator;
    UIBarButtonItem *buttonGoBack;
    UIBarButtonItem *buttonGoForward;
    
    // Customization
    TSMiniWebBrowserMode mode;
    BOOL showURLStringOnActionSheetTitle;
    BOOL showPageTitleOnTitleBar;
    BOOL showReloadButton;
    BOOL showActionButton;
    UIBarStyle barStyle;
	UIColor *barTintColor;
    NSString *modalDismissButtonTitle;
    NSString *forcedTitleBarText;
    
    // State control
    UIBarStyle originalBarStyle;
}

@property (assign) id<TSMiniWebBrowserDelegate> delegate;

@property (nonatomic, assign) TSMiniWebBrowserMode mode;
@property (nonatomic, assign) BOOL showURLStringOnActionSheetTitle;
@property (nonatomic, assign) BOOL showPageTitleOnTitleBar;
@property (nonatomic, assign) BOOL showReloadButton;
@property (nonatomic, assign) BOOL showActionButton;
@property (nonatomic, assign) UIBarStyle barStyle;
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, strong) NSString *modalDismissButtonTitle;
@property (nonatomic, strong) NSString *domainLockList;
@property (nonatomic, strong) NSString *currentURL;

// Public Methods
- (id)initWithUrl:(NSURL*)url;
- (void)setFixedTitleBarText:(NSString*)newTitleBarText;
- (void)loadURL:(NSURL*)url;
@end
