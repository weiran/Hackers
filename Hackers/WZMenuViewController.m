//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 16/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZMenuViewController.h"
#import "WZAppDelegate.h"

#import <JSSlidingViewController.h>

@interface WZMenuViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsCell;

@end

@implementation WZMenuViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[tableView indexPathForCell:_settingsCell]]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UINavigationController *settingsNavController = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
        WZAppDelegate *delegate = [WZDefaults appDelegate];
        [delegate.viewController setFrontViewController:settingsNavController animated:YES completion:nil];
        [delegate.viewController closeSlider:YES completion:nil];
    }
}

@end
