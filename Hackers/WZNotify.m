//
//  WZNotify.m
//  Hackers
//
//  Created by Weiran Zhang on 01/03/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#define kContainerHorizontalPadding 15
#define kContainerVerticalPadding 5

#import <QuartzCore/QuartzCore.h>

#import "WZNotify.h"

@interface WZNotify ()

@end

@implementation WZNotify

+ (void)showMessage:(NSString *)message inView:(UIView *)view duration:(CGFloat)duration {
    UIView *containerView = [[UIView alloc] init];
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.font = [UIFont systemFontOfSize:14];
    
    containerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    containerView.opaque = NO;
    containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    containerView.layer.shadowOpacity = 0.8;
    containerView.layer.shadowRadius = 3;
    containerView.layer.shadowOffset = CGSizeMake(0, 0);
    textLabel.textColor = [UIColor whiteColor];
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.text = message;
    
    CGSize labelSize = [message sizeWithFont:textLabel.font];
    CGRect labelFrame = CGRectMake(kContainerHorizontalPadding, kContainerVerticalPadding, labelSize.width, labelSize.height);
    textLabel.frame = labelFrame;
    
    CGRect parentViewFrame = view.frame;
    CGFloat containerFrameWidth = kContainerHorizontalPadding * 2 + labelSize.width;
    CGFloat containerFrameHeight = kContainerVerticalPadding * 2 + labelSize.height;
    CGFloat x = (parentViewFrame.size.width / 2) - (containerFrameWidth / 2);
    CGRect containerFrame = CGRectMake(x, parentViewFrame.size.height, containerFrameWidth, containerFrameHeight);
    containerView.frame = containerFrame;
    containerView.layer.cornerRadius = containerFrame.size.height / 2;
    
    [containerView addSubview:textLabel];
    [view addSubview:containerView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect visibleContainerFrame = CGRectMake(containerFrame.origin.x, parentViewFrame.size.height - containerFrame.size.height - 20, containerFrame.size.width, containerFrame.size.height);
                         containerView.frame = visibleContainerFrame;
                         
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3
                                               delay:duration
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              containerView.frame = containerFrame;
                                          } completion:^(BOOL finished) {
                                              [containerView removeFromSuperview];
                                          }];
                     }];
}

@end
