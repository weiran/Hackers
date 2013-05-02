//
//  WZAccountManager.m
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZAccountManager.h"
#import "WZHackersDataAPI.h"
#import "WZNotify.h"

#import <SSKeychain.h>

@interface WZAccountManager () {
    NSString *_url;
    NSString *_title;
    NSString *_service;
}
@end

@implementation WZAccountManager

+ (WZAccountManager *)shared {
    static WZAccountManager *__accountManager = nil;
    if (__accountManager == nil) {
        __accountManager = [WZAccountManager new];
    }
    return __accountManager;
}

+ (void)setPassword:(NSString *)password forService:(NSString *)service {
    NSString *passwordKey = [service stringByAppendingString:@"Password"];
    [SSKeychain setPassword:password forService:service account:@""];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@"Password" forKey:passwordKey];
    [defaults synchronize];
}

+ (NSString *)passwordForService:(NSString *)service {
    return [SSKeychain passwordForService:service account:@""];
}

- (void)sendURL:(NSString *)url toService:(NSString *)service {
    [self sendURL:url title:nil toService:service];
}

- (void)sendURL:(NSString *)url title:(NSString *)title toService:(NSString *)service {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
    
    _url = url;
    _title = title;
    _service = service;
    
    if (username.length > 0) {
        if ([service isEqualToString:kSettingsInstapaper]) {
            [self sendToInstapaperUrl:url];
        } else if ([service isEqualToString:kSettingsPinboard]) {
            [self sendToPinboardUrl:url title:title];
        }
    } else {
        [self showAuthenticateAlertFromWrongPassword:NO forService:service];
    }
}

- (void)showAuthenticateAlertFromWrongPassword:(BOOL)wrongPassword forService:(NSString *)service {
    
//    NSString *incorrectCredentialsMessage = [NSString stringWithFormat:@"Your existing %@ credentials are wrong", service];
//    NSString *enterCredentialsMessage = [NSString stringWithFormat:@"Enter your %@ credentials", service];
//    
//    NSString *message = wrongPassword ? incorrectCredentialsMessage : enterCredentialsMessage;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Login to %@", service]
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Login", nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    
    [alertView show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            // Cancel
            break;
        }
            
        case 1: {
            // Login
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *username = [alertView textFieldAtIndex:0].text;
            if ([_service isEqualToString:kSettingsInstapaper]) {
                [defaults setValue:username forKey:kSettingsInstapaperUsername];
            } else if ([_service isEqualToString:kSettingsPinboard]) {
                [defaults setValue:username forKey:kSettingsPinboardUsername];
            }
            [defaults synchronize];
            NSString *password = [alertView textFieldAtIndex:1].text;
            [WZAccountManager setPassword:password forService:_service];
            
            if ([_service isEqualToString:kSettingsInstapaper]) {
                [self sendToInstapaperUrl:_url];
            } else if ([_service isEqualToString:kSettingsPinboard]) {
                [self sendToPinboardUrl:_url title:_title];
            }
            break;
        }
        default:
            break;
    }
}

- (void)sendToInstapaperUrl:(NSString *)url {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
        NSString *password = [WZAccountManager passwordForService:kSettingsInstapaper];
        [[WZHackersDataAPI shared] sendToInstapaper:url username:username password:password completion:^(BOOL success, BOOL invalidCredentials) {
            if (!success && invalidCredentials) {
                [self showAuthenticateAlertFromWrongPassword:YES forService:kSettingsInstapaper];
            }
            
            if (success) {
                [WZNotify showMessage:@"Sent to Instapaper" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }
        }];
    });
}

- (void)sendToPinboardUrl:(NSString *)url title:(NSString *)title {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsPinboardUsername];
        NSString *password = [WZAccountManager passwordForService:kSettingsPinboard];
        [[WZHackersDataAPI shared] sendToPinboardUrl:_url title:_title username:username password:password completion:^(BOOL success, BOOL invalidCredentials) {
            if (!success && invalidCredentials) {
                [self showAuthenticateAlertFromWrongPassword:YES forService:kSettingsPinboard];
            }
            
            if (success) {
                [WZNotify showMessage:@"Sent to Pinboard" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }
        }];
    });
}

@end
