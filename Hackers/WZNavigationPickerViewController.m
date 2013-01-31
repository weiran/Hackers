//
//  WZNavigationPickerViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 30/01/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZNavigationPickerViewController.h"
#import "WZNavigationPickerView.h"
#import <QuartzCore/QuartzCore.h>

@interface WZNavigationPickerViewController ()

@end

@implementation WZNavigationPickerViewController

- (void)viewDidLoad {
    CGFloat x = 0;
    CGFloat y = self.navigationController.navigationBar.frame.size.height;
    CGFloat width = self.navigationController.navigationBar.frame.size.width;
    
    WZNavigationPickerView *pickerView = [[WZNavigationPickerView alloc] initWithFrame:CGRectMake(x, y, width, 88)];
    pickerView.layer.opacity = 0;
    [self.view addSubview:pickerView];
    
    CATransition *transition = [CATransition new];
    transition.type = kCATransitionFade;
    transition.duration = 0.2;
    [self.view.layer addAnimation:transition forKey:@"opacity"];
    
    pickerView.layer.opacity = 1;
    [pickerView becomeFirstResponder];

}

@end
