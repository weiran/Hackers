//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 16/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZMenuViewController.h"
#import "WZNavigationController.h"
#import "WZAccountManager.h"
#import "WZNavigationBar.h"

#import <JSSlidingViewController.h>
#import <IASKSpecifierValuesViewController.h>
#import <IASKSettingsReader.h>
#import <SSKeychain.h>

@interface WZMenuViewController ()
@property (nonatomic, strong) WZNavigationController *settingsNavController;
@property (nonatomic, strong) IASKAppSettingsViewController *settingsViewController;
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *askCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showNewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *topCell;

@end

@implementation WZMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // setup theme notification
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kSettingsTheme options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // setup theme notification
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kSettingsTheme];
}

- (WZNavigationController *)mainNavViewController {
    if (!_mainNavViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        _mainNavViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    }
    
    return _mainNavViewController;
}

- (IASKAppSettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        _settingsViewController = [[IASKAppSettingsViewController alloc] init];
        _settingsViewController.delegate = self;
        _settingsViewController.showDoneButton = NO;
        _settingsViewController.showCreditsFooter = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 44, 44);
        button.accessibilityLabel = @"menu";
        [button setImage:[UIImage imageNamed:@"menu-icon"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(toggleSlider) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
        [_settingsViewController.navigationItem setLeftBarButtonItem:menuBarButtonItem];
    }
    
    return _settingsViewController;
}

-(UINavigationController *)settingsNavController {
    if (!_settingsNavController) {
        _settingsNavController = [[WZNavigationController alloc] initWithRootViewController:self.settingsViewController];
        [_settingsNavController setValue:[[WZNavigationBar alloc]init] forKeyPath:@"navigationBar"];
    }
    
    return _settingsNavController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    _mainNavViewController = nil;
    _settingsNavController = nil;
    _settingsViewController = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[tableView indexPathForCell:_settingsCell]]) {
        if (![[[WZDefaults appDelegate] viewController].frontViewController isEqual:self.settingsNavController]) {
            [[[WZDefaults appDelegate] viewController] setFrontViewController:self.settingsNavController animated:YES completion:nil];
        }
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_topCell]]) {
        [self showMainNavViewController];
        [self.mainNavViewController setNewsType:WZNewsTypeTop];
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_showNewCell]]) {
        [self showMainNavViewController];
        [self.mainNavViewController setNewsType:WZNewsTypeNew];
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_askCell]]) {
        [self showMainNavViewController];
        [self.mainNavViewController setNewsType:WZNewsTypeAsk];
        [self toggleSlider];
    }
}

- (void)showMainNavViewController {
    if (![[[[WZDefaults appDelegate] viewController] frontViewController ] isEqual:self.mainNavViewController]) {
        [[[WZDefaults appDelegate] viewController] setFrontViewController:self.mainNavViewController animated:YES completion:nil];
    }
}

- (void)toggleSlider {
    if ([[[WZDefaults appDelegate] viewController] isOpen]) {
        [[[WZDefaults appDelegate] viewController] closeSlider:YES completion:nil];
    } else {
        [[[WZDefaults appDelegate] viewController] openSlider:YES completion:nil];
    }
}

#pragma mark - IASKAppSettingsViewControllerDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    //[self dismissModalViewControllerAnimated:YES];
    
}

#pragma mark kIASKAppSettingChanged notification
- (void)settingDidChange:(NSNotification*)notification {
	if ([notification.object isEqual:kSettingsInstapaperPassword]) {
        NSString *password = notification.userInfo[kSettingsInstapaperPassword];
        [WZAccountManager setPassword:password forService:kSettingsInstapaper];
	}
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //    [WZTheme defaults];
    [WZTheme updateNavigationBar:_mainNavViewController];
    [WZTheme updateNavigationBar:_settingsNavController];
    _mainNavViewController.title = @"Test";
    _settingsNavController.title = @"Test";
}

@end
