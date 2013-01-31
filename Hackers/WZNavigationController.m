//
//  WZNavigationController.m
//  Hackers
//
//  Created by Weiran Zhang on 30/01/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationController.h"
#import "WZNavigationPickerViewController.h"

@interface WZNavigationController ()

- (IBAction)navigationBarTapped:(id)sender;
@end

@implementation WZNavigationController

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![[touch.view class] isSubclassOfClass:[UIControl class]];
}

- (IBAction)navigationBarTapped:(id)sender {
    WZNavigationPickerViewController *pickerViewController = [[WZNavigationPickerViewController alloc] init];
    [self.view addSubview:pickerViewController.view];
}
@end
