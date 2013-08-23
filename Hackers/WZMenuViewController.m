//
//  WZMenuViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 16/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZMenuViewController.h"
#import "WZNavigationController.h"
#import "WZSettingsViewController.h"
#import "WZActivityManager.h"
#import "WZNavigationBar.h"

#import "JSSlidingViewController.h"
#import <IASKSpecifierValuesViewController.h>
#import <IASKSettingsReader.h>
#import <SSKeychain.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+iOS.h>
#import "UIViewController+CLCascade.h"

@interface WZMenuViewController ()
@property (nonatomic, strong) WZNavigationController *settingsNavController;
@property (nonatomic, strong) WZSettingsViewController *settingsViewController;
@property (nonatomic, strong) UIViewController *creditsViewController;
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *askCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *showNewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *topCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *creditsCell;

@end

@implementation WZMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self layoutTableView];
    
    if (IS_IPAD()) {
        double delayInSeconds = 0.05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            dispatch_async(dispatch_get_main_queue(), ^{
               [self showMainNavViewControllerWithNewsType:WZNewsTypeTop];
            });
        });

    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // setup theme notification
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kSettingsTheme options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self.tableView indexPathForSelectedRow]) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // setup theme notification
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kSettingsTheme];
}

- (void)layoutTableView {
    self.tableView.scrollsToTop = NO;
    self.tableView.backgroundColor = [WZTheme menuBackgroundColor];
    self.tableView.separatorColor = [WZTheme menuSeparatorColor];
    
    [self layoutCell:_settingsCell];
    [self layoutCell:_askCell];
    [self layoutCell:_showNewCell];
    [self layoutCell:_topCell];
    [self layoutCell:_creditsCell];
    
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory tabBarItemIconFactory];
    [_settingsCell.imageView setImage:[factory createImageForIcon:NIKFontAwesomeIconCog]];
    [_askCell.imageView setImage:[factory createImageForIcon:NIKFontAwesomeIconQuestionSign]];
    [_showNewCell.imageView setImage:[factory createImageForIcon:NIKFontAwesomeIconTime]];
    [_topCell.imageView setImage:[factory createImageForIcon:NIKFontAwesomeIconStar]];
    [_creditsCell.imageView setImage:[factory createImageForIcon:NIKFontAwesomeIconInfoSign]];
}

- (void)layoutCell:(UITableViewCell *)cell {
    cell.backgroundColor = [WZTheme menuBackgroundColor];
    cell.textLabel.textColor = [WZTheme menuTitleColor];
    cell.textLabel.font = [UIFont fontWithName:kNavigationFontName size:kNavigationFontSize];
    cell.textLabel.highlightedTextColor = [UIColor blackColor];
}

- (WZNavigationController *)mainNavViewController {
    if (!_mainNavViewController) {
        NSString *storyboardName = IS_IPAD() ? @"MainStoryboard_ipad" : @"MainStoryboard";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
        _mainNavViewController = [storyboard instantiateViewControllerWithIdentifier:@"MainNavigationController"];
    }
    
    return _mainNavViewController;
}

- (IASKAppSettingsViewController *)settingsViewController {
    if (!_settingsViewController) {
        _settingsViewController = [[WZSettingsViewController alloc] init];
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
        if (IS_IPAD()) {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
            [self.cascadeNavigationController setRootViewController:navController animated:YES];
        } else {
            if (![[[WZDefaults appDelegate] phoneViewController].frontViewController isEqual:self.settingsNavController]) {
                [[[WZDefaults appDelegate] phoneViewController] setFrontViewController:self.settingsNavController animated:YES completion:nil];
            }
        }
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_topCell]]) {
        [self showMainNavViewControllerWithNewsType:WZNewsTypeTop];
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_showNewCell]]) {
        [self showMainNavViewControllerWithNewsType:WZNewsTypeNew];
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:_askCell]]) {
        [self showMainNavViewControllerWithNewsType:WZNewsTypeAsk];
        [self toggleSlider];
    } else if ([indexPath isEqual:[tableView indexPathForCell:self.creditsCell]]) {
        if (!self.creditsViewController) {
            self.creditsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CreditsViewController"];
        }
        
        if (IS_IPAD()) {
            [self.cascadeNavigationController setRootViewController:self.creditsViewController animated:YES];
        } else {
            if (![[[WZDefaults appDelegate] phoneViewController].frontViewController isEqual:self.creditsViewController]) {
                [[[WZDefaults appDelegate] phoneViewController] setFrontViewController:self.creditsViewController animated:YES completion:nil];
                [self toggleSlider];
            }
        }
    }
}

- (void)showMainNavViewControllerWithNewsType:(WZNewsType)newsType {
    [self.mainNavViewController setNewsType:newsType];
    if (IS_IPAD()) {
        if (self.cascadeNavigationController.rootViewController != self.mainNavViewController) {
            [self.cascadeNavigationController setRootViewController:self.mainNavViewController animated:YES];
        }
    } else {
        if (![[[[WZDefaults appDelegate] phoneViewController] frontViewController] isEqual:self.mainNavViewController]) {
            [[[WZDefaults appDelegate] phoneViewController] setFrontViewController:self.mainNavViewController animated:YES completion:nil];
        }
    }
}

- (void)toggleSlider {
    if ([[[WZDefaults appDelegate] phoneViewController] isOpen]) {
        [[[WZDefaults appDelegate] phoneViewController] closeSlider:YES completion:nil];
    } else {
        [[[WZDefaults appDelegate] phoneViewController] openSlider:YES completion:nil];
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
        [WZActivityManager setPassword:password forService:kSettingsInstapaper];
	}
}

#pragma Settings Changed
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [WZTheme defaults];
    if ([keyPath isEqualToString:kSettingsTheme]) {
        self.mainNavViewController = nil;
    }
}

@end
