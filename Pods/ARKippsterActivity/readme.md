# ARKippsterActivity

[Kippster](http://kippster.net/) is a [Kippt](https://kippt.com/) client for iOS. This UIActivity subclass will allow your users to easily share URLs to Kippt via Kippster in the standard iOS 6 share sheet.

## Installation and Setup

1. Drag the ARKippsterActivity folder containing the `.h`, `.m`, and `kippster-activity` PNG files into your Xcode project.

2. `#import "ARKippsterActivity.h"`

3. Initialize a `UIActivityViewController`, activity items including a URL, and `ARKippsterActivity` along with any other `UIActivity` subclasses you might be using (e.g. `[ARChromeActivity](https://github.com/alextrob/ARChromeActivity)`).

  ```objc
  NSURL *urlToShare = [NSURL URLWithString:@"http://kippster.net"];
  NSArray *activityItems = @[urlToShare];
  
  ARKippsterActivity *kippsterActivity = [[ARKippsterActivity alloc] initWithCallbackURL:[NSURL URLWithString:@"kippsteractivitydemo://"]];
  
  UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[kippsterActivity]];
  ```
4. Present the view controller. For iPhone, that's as easy as:

  ```objc
  [self presentViewController:activityViewController animated:YES completion:nil];
  ```

On iPad, you'll need to present it in a `UIPopoverViewController`. See the demo app for details.
