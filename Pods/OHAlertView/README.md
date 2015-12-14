[![Version](http://cocoapod-badges.herokuapp.com/v/OHAlertView/badge.png)](http://cocoadocs.org/docsets/OHAlertView)
[![Platform](http://cocoapod-badges.herokuapp.com/p/OHAlertView/badge.png)](http://cocoadocs.org/docsets/OHAlertView)


## About this class

This class make it easier to use `UIAlertView` with blocks.

This allows you to provide directly the code to execute (as a block) in return to the tap on a button,
instead of declaring a delegate and implementing the corresponding methods.

This also has the huge advantage of **simplifying the code especially when using multiple `UIAlertViews`** in the same object (as in such case, it is not easy to have a clean code if you share the same delegate)

_Note: You may also be interested in [OHActionSheet](https://github.com/AliSoftware/OHActionSheet)_

## Usage Example

    [OHAlertView showAlertWithTitle:@"Alert Demo"
                            message:@"You like this sample?"
                       cancelButton:@"No"
                           okButton:@"Yes"
                      buttonHandler:^(OHAlertView* alert, NSInteger buttonIndex)
     {
         NSLog(@"button tapped: %d",buttonIndex);
     
         if (buttonIndex == alert.cancelButtonIndex) {
             NSLog(@"No");
         } else {
             NSLog(@"Yes");
         }
     }];
     
## Alerts with timeout

You can also use this class to generate an AlertView that will be dismissed after a given time.
_(You can even add a dynamic text on your alert to display the live countdown)_

    [[[OHAlertView alloc] initWithTitle:@"Alert Demo"
                                message:@"This is a demo message"
                           cancelButton:nil
                           otherButtons:[NSArray arrayWithObject:@"OK"]
                          buttonHandler:^(OHAlertView* alert, NSInteger buttonIndex)
      {
          if (buttonIndex == -1)
          {
              self.status.text = @"Demo alert dismissed automatically after timeout!";
          }
          else
          {
              self.status.text = @"Demo alert dismissed by user!";
          }
      }] showWithTimeout:12 timeoutButtonIndex:-1 timeoutMessageFormat:@"(Alert dismissed in %lus)"];

## CocoaPods

This class is referenced in CocoaPods, so you can simply add `pod OHAlertView` to your Podfile to add it to your pods.

## Compatibility Notes

* This class uses blocks, which is a feature introduced in iOS 4.0.
* This class uses ARC.

## License

This code is under MIT License.
