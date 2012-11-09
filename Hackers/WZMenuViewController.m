//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZMenuViewController.h"

@interface WZMenuViewController ()

@end

@implementation WZMenuViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.slideMenuDataSource = self;
}

- (NSString *)initialSegueId {
    return @"TopNewsSegue";
}

- (void)configureMenuButton:(UIButton *)menuButton {
    menuButton.frame = CGRectMake(0, 0, 40, 29);
    menuButton.titleLabel.text = @"M";
}

@end
