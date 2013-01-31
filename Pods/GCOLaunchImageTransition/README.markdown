## GCOLaunchImageTransition

Animates the transition from the launch image to the app's initial view controller on iOS. Includes customized animation delay and duration, triggering the transition via notification and display of an activity indicator.

If you're using this pod or found it somehow useful, I'd be happy if you'd [let me know](mailto:michael@gonecoding.com).


## Features

- Use one of three animations to create a nice transition from your launch image to your app:
 - Fade
 - Zoom In (with Fade)
 - Zoom Out (with Fade)
- Choose a custom delay before the animation begins
- Choose a custom duration for the animation effect
- Easily add an activity indicator with custom position and style
- Dismiss the transition manually by posting a notification


## Example project

To see this pod in action before using it in your project you should download the repository and have a look at the example project that's included.

[Download repository as ZIP archive](https://github.com/gonecoding/GCOLaunchImageTransition/archive/master.zip)


## Installation via CocoaPods

Adding this pod to your project using [CocoaPods](http://cocoapods.org) is a one-liner in your Podfile:

``` ruby
pod 'GCOLaunchImageTransition'
```

Now run `pod install` to have CocoaPods handle everything for you.  
Never heard of CocoaPods? Do yourself a favor and [check it out now](http://cocoapods.org).


## Usage

The easiest way is to add the following code to your app delegate (e. g. AppDelegate.m):

```objective-c
#import <GCOLaunchImageTransition/GCOLaunchImageTransition.h>

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   [...]

   // Add transition from the launch image to the root view controller's view
   [GCOLaunchImageTransition transitionWithDuration:0.5 style:GCOLaunchImageTransitionAnimationStyleZoomIn];
}
```

Don't worry, although this code is being added to `-applicationDidBecomeActive` the code for creating the transition is only executed once — Grand Central Dispatch sees to that with its `dispatch_once()` method.

You can also create a transition with a (near-)infinite delay that can be dismissed at a specific point by posting a notification:

```objective-c
#import <GCOLaunchImageTransition/GCOLaunchImageTransition.h>

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   [...]

   // Create transition with an near-infinite delay that requires manual dismissal via notification
   [GCOLaunchImageTransition transitionWithInfiniteDelayAndDuration:0.5 style:GCOLaunchImageTransitionAnimationStyleFade];
}

// At some point within your app's startup code dismiss the transition by posting a notification

- (void)someStartupProcedureDidFinish
{
   [[NSNotificationCenter defaultCenter] postNotificationName:GCOLaunchImageTransitionHideNotification object:self];
}
```

Finally you can add an activity indicator to the launch image transition using the fully customizable transition creation:

```objective-c
#import <GCOLaunchImageTransition/GCOLaunchImageTransition.h>

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   [...]

   // Create fully customizable transition including an optional activity indicator
   // The 'activityIndicatorPosition' is a percentage value ('CGPointMake( 0.5, 0.5 )' being the center)

   [GCOLaunchImageTransition transitionWithDelay:5.0 duration:0.5 style:GCOLaunchImageTransitionAnimationStyleZoomOut activityIndicatorPosition:CGPointMake( 0.5, 0.9 ) activityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
}
```

Note: You can always use `GCOLaunchImageTransitionNearInfiniteDelay` for the delay parameter if you prefer to dismiss the transition manually. 

## ARC Compatibility

This pod is compatible with ARC enabled projects by default. CocoaPods will handle the ARC settings for you.


## Contributing 

I absolutely appreciate any suggestions or improvements you may have in mind for this pod. That being said the most welcomed form of contribution would be a pull request from [your own fork of this repository](https://help.github.com/articles/fork-a-repo) on GitHub. If you only have a minor problem or suggestion consider opening an [issue](https://github.com/gonecoding/GCOLaunchImageTransition/issues).


## Contact

I'm [Michael Sedlaczek](mailto:michael@gonecoding.com), [Gone Coding](http://gonecoding.com). I'm also using Twitter: [@gonecoding](https://twitter.com/gonecoding)


## License

GCOLaunchImageTransition is released under the [New BSD License](http://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_.28.22Revised_BSD_License.22.2C_.22New_BSD_License.22.2C_or_.22Modified_BSD_License.22.29). For details see [LICENSE](https://github.com/gonecoding/GCOLaunchImageTransition/blob/master/LICENSE).  
This license requires attribution when redistributing the component as source code or in binary form.
