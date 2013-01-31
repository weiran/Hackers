//
//  WZMainViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WZHackersData.h"

@interface WZMainViewController : UITableViewController <UIGestureRecognizerDelegate>

@property (nonatomic) WZNewsType newsType;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (void)updateNavigationBarBackground;
@end
