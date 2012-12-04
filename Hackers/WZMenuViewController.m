//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZMenuViewController.h"

#import "WZMainViewController.h"
#import "WZHackersData.h"

@interface WZMenuViewController ()

@end

@implementation WZMenuViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.slideMenuDataSource = self;
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                animated:NO
                          scrollPosition:UITableViewScrollPositionTop];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navigationController = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"TopNewsSegue"]) {
        WZMainViewController *mainViewController = navigationController.viewControllers[0];
        mainViewController.newsType = WZNewsTypeTop;
    } else if ([segue.identifier isEqualToString:@"NewNewsSegue"]) {
        WZMainViewController *mainViewController = navigationController.viewControllers[0];
        mainViewController.newsType = WZNewsTypeNew;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (NSString *)initialSegueId {
    return @"TopNewsSegue";
}

- (void)configureMenuButton:(UIButton *)menuButton {

}

@end
