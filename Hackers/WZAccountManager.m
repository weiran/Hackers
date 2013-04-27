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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
    _url = url;
    
    if (username.length > 0) {
        [self sendToInstapaper];
    } else {
        [self showAuthenticateAlertFromWrongPassword:NO];
    }
}

- (void)showAuthenticateAlertFromWrongPassword:(BOOL)wrongPassword {
    NSString *message = wrongPassword ? @"Your existing credentials are wrong" : @"Enter your Instapaper credentials";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login to Instapaper"
                                                        message:message
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
            [defaults setValue:username forKey:kSettingsInstapaperUsername];
            [defaults synchronize];
            NSString *password = [alertView textFieldAtIndex:1].text;
            [WZAccountManager setPassword:password forService:kSettingsInstapaper];
            
            [self sendToInstapaper];
            break;
        }
        default:
            break;
    }
}

- (void)sendToInstapaper {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
        NSString *password = [WZAccountManager passwordForService:kSettingsInstapaper];
        [[WZHackersDataAPI shared] sendToInstapaper:_url username:username password:password completion:^(BOOL success, BOOL invalidCredentials) {
            if (!success && invalidCredentials) {
                [self showAuthenticateAlertFromWrongPassword:YES];
            }
            
            if (success) {
                [WZNotify showMessage:@"Sent to Instapaper" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }
        }];
    });
}

@end
