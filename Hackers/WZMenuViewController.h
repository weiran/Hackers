//
//  WZMenuViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 16/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IASKAppSettingsViewController.h>
#import "CLCategoriesViewController.h"

@class WZNavigationController;

@interface WZMenuViewController : UITableViewController <IASKSettingsDelegate>

@property (nonatomic, strong) WZNavigationController *mainNavViewController;

@end
