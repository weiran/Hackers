JBWebViewController
===================

A drop-in Facebook inspired modal web browser.

<img src="https://raw.githubusercontent.com/boserup/JBWebViewController/master/Example/screenshot.png" alt="JBWebViewController Screenshot" width="400" height="720">

## Video Demo
<a href="http://www.youtube.com/watch?feature=player_embedded&v=pyNy3VuTJTs
" target="_blank"><img src="http://img.youtube.com/vi/pyNy3VuTJTs/0.jpg" 
alt="JBWebViewController Video Demo" width="240" height="180" border="10" /></a>

## Installation

### CocoaPods
The recommended approach for installing JBWebViewController is through the package manager [CocoaPods](http://cocoapods.org/), which is widely used by iOS & Mac developers.

Simply add the following line to your Podfile:
```ruby
pod "JBWebViewController"
```

### Manual Install
Drag the JBWebViewController folder into your Xcode project, you may need to check the box "Copy items into destination group's folder (if needed)".

JBWebViewController needs the following third-party libraries:
* [ARChromeActivity](https://github.com/alextrob/ARChromeActivity)
* [ARSafariActivity](https://github.com/alexruperez/ARSafariActivity)
* [NJKWebViewProgress](https://github.com/ninjinkun/NJKWebViewProgress)

## How to use
JBWebViewController is ment to be shown modally, which is recommended to be down with it's built in show functionality. Whilst not being recommended, it is however possible to present JBWebViewController outside a modal view controller. JBWebViewController should always be connected to a UINavigationController.

#### Presenting JBWebViewController
```objectivec
JBWebViewController *controller = [[JBWebViewController alloc] initWithUrl:[NSURL URLWithString:@"http://www.apple.com/iphone/"]];

[controller show];
```

#### Presenting JBWebViewController with block
```objectivec
JBWebViewController *controller = [[JBWebViewController alloc] initWithUrl:[NSURL URLWithString:@"http://www.apple.com/iphone/"]];

[controller showControllerWithCompletion:^(JBWebViewController *controller) {
    NSLog(@"Controller has arrived.");
}];
```

#### Localization
```objectivec
[controller setLoadingString:@"Chargement.."];
```

#### Navigate to URL
```objectivec
[controller navigateToURL:[NSURL URLWithString:@"http://www.apple.com/ios/"]];
```

#### Load custom NSURLRequest
```objectivec
NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://developer.apple.com/"]];
[controller loadRequest:request];
```

#### Reload current page
```objectivec
[controller reload];
```

#### Manually setting controller title
```objectivec
[controller setWebTitle:@"The quick brown fox"];
```

#### Getting controller title
```objectivec
NSString *controllerTitle = [controller getWebTitle];
```

#### Manually setting controller subtitle
```objectivec
[controller setWebSubtitle:@"foo bar"];
```

#### Getting controller subtitle
```objectivec
NSString *controllerSubtitle = [controller getWebSubtitle];
```

#### Hide URL
```objectivec
controller.hideAddressBar = YES;
```

#### Access UIWebView
The UIWebView used in the controller is now pubic.
```objectivec
UIWebView *webView;
```

## Apps using JBWebViewController
- [Ookull](http://itunes.apple.com/app/id934603488?mt=8)

Feel free to add your app to the list.

## Icons
Free icons by [Icons8](http://icons8.com/) under [Creative Commons Attribution-NoDerivs 3.0 Unported](https://creativecommons.org/licenses/by-nd/3.0/).

## Contact

Mention me on Twitter ([@JonasBoserup](https://twitter.com/JonasBoserup)) or email me ([Profile](https://github.com/boserup)).

## License

JBWebViewController is available under the MIT license. See the LICENSE file for more info.
