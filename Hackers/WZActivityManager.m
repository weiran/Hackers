//
//  WZAccountManager.m
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZActivityManager.h"
#import "WZHackersDataAPI.h"
#import "WZNotify.h"

#import "NNNetwork/NNNetwork.h"
#import "NNNetwork/NNOAuth1Credential.h"
#import "OHAlertView.h"
#import "AFHTTPRequestOperation.h"

#import <SSKeychain.h>

@interface WZActivityManager ()
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *service;
@end

@implementation WZActivityManager

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

- (void)sendURL:(NSURL *)url toService:(NSString *)service {
    _url = url;
    _title = nil;
    _service = service;
    
    [self send];
}

- (void)sendURL:(NSURL *)url title:(NSString *)title toService:(NSString *)service {
    _url = url;
    _title = title;
    _service = service;
    
    [self send];
}

- (void)send {
    if ([self.service isEqualToString:kSettingsInstapaper] || [self.service isEqualToString:kSettingsPinboard]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
        
        if (username.length > 0) {
            if ([self.service isEqualToString:kSettingsInstapaper]) {
                [self sendToInstapaper];
            } else if ([self.service isEqualToString:kSettingsPinboard]) {
                [self sendToPinboard];
            }
        } else {
            [self showAuthenticateAlertFromWrongPassword:NO];
        }
    } else if ([self.service isEqualToString:kSettingsPocket]) {
        NNOAuthCredential *pocketCredentails = [NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier]
                                                                                           account:[[NNPocketClient sharedClient] name]];
        if (!pocketCredentails) {
            [self authorisePocket];
        } else {
            [self sendToPocket];
        }
    } else if ([self.service isEqualToString:kSettingsReadability]) {
        NNOAuthCredential *readabilityCredentials = [NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier]
                                                                                                account:[[NNReadabilityClient sharedClient] name]];
        if (!readabilityCredentials) {
            [self showAuthenticateAlertFromWrongPassword:NO];
        } else {
            [self sendToReadability];
        }
    }
}


- (void)showAuthenticateAlertFromWrongPassword:(BOOL)wrongPassword {
    OHAlertView *alertView = [[OHAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Login to %@", self.service]
                                                        message:nil
                                              cancelButton:@"Cancel"
                                              otherButtons:@[@"Login"]
                                             buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                                                 if (buttonIndex == 1) {
                                                     [self authoriseWithAlertView:alert];
                                                 }
                                             }];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    
    [alertView show];
}

- (void)authorisePocket {
    NNPocketClient *client = [NNPocketClient sharedClient];
    [client authorizeWithSuccess:^(AFHTTPRequestOperation *operation, NSString *username, NNOAuth2Credential *credential) {
        [self saveCredential:credential withUsername:username];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [WZNotify showMessage:@"Can't login to Pocket" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
    }];
}

- (void)authoriseWithAlertView:(UIAlertView *)alertView {
    NSString *username = [alertView textFieldAtIndex:0].text;
    NSString *password = [alertView textFieldAtIndex:1].text;
    [self authoriseWithUsername:username password:password];
}

- (void)authoriseWithUsername:(NSString *)username password:(NSString *)password {
    if ([self.service isEqualToString:kSettingsInstapaper] || [self.service isEqualToString:kSettingsPinboard]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([_service isEqualToString:kSettingsInstapaper]) {
            [defaults setValue:username forKey:kSettingsInstapaperUsername];
        } else if ([_service isEqualToString:kSettingsPinboard]) {
            [defaults setValue:username forKey:kSettingsPinboardUsername];
        }
        [defaults synchronize];
        [WZActivityManager setPassword:password forService:_service];
        
        if ([_service isEqualToString:kSettingsInstapaper]) {
            [self sendToInstapaper];
        } else if ([_service isEqualToString:kSettingsPinboard]) {
            [self sendToPinboard];
        }
    } else if ([self.service isEqualToString:kSettingsReadability]) {
        NNReadabilityClient *client = [NNReadabilityClient sharedClient];
        [client credentialWithUsername:username password:password success:^(AFHTTPRequestOperation *operation, NNOAuthCredential *credential) {
            [self saveCredential:credential withUsername:nil];
            [self sendToReadability];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // show incorrect user/pass alert
            [WZNotify showMessage:@"The username or password you entered is incorrect." inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0];
            [self send];
        }];
    } else if ([self.service isEqualToString:kSettingsPocket]) {
        NNPocketClient *client = [NNPocketClient sharedClient];
        [client authorizeWithSuccess:^(AFHTTPRequestOperation *operation, NSString *username, NNOAuth2Credential *credential) {
            [self saveCredential:credential withUsername:username];
            [self sendToPocket];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WZNotify showMessage:NSLocalizedString(@"Couldn't login to Pocket", nil) inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
        }];
    }
}

- (void)saveCredential:(NNOAuthCredential *)credential withUsername:(NSString *)username {
    if ([self.service isEqualToString:kSettingsPocket]) {
        NNOAuth2Credential *newCredential;
        if (username) {
            newCredential = [[NNOAuth2Credential alloc] initWithAccessToken:credential.accessToken userInfo:@{ @"AccountName" : username }];
            [newCredential saveToKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:self.service];
        } else {
            [credential saveToKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:self.service];
        }
    } else if ([self.service isEqualToString:kSettingsReadability]) {
        [credential saveToKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:self.service];
    }
}

- (void)sendToInstapaper {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsInstapaperUsername];
        NSString *password = [WZActivityManager passwordForService:kSettingsInstapaper];
        [[WZHackersDataAPI shared] sendToInstapaper:self.url.absoluteString username:username password:password completion:^(BOOL success, BOOL invalidCredentials) {
            if (!success && invalidCredentials) {
                [self showAuthenticateAlertFromWrongPassword:YES];
            }
            
            if (success) {
                [WZNotify showMessage:@"Sent to Instapaper" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }
        }];
    });
}

- (void)sendToPinboard {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults stringForKey:kSettingsPinboardUsername];
        NSString *password = [WZActivityManager passwordForService:kSettingsPinboard];
        [[WZHackersDataAPI shared] sendToPinboardUrl:self.url.absoluteString title:self.title username:username password:password completion:^(BOOL success, BOOL invalidCredentials) {
            if (!success && invalidCredentials) {
                [self showAuthenticateAlertFromWrongPassword:YES];
            }
            
            if (success) {
                [WZNotify showMessage:@"Sent to Pinboard" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }
        }];
    });
}

- (void)sendToPocket {
    NNPocketClient *client = [NNPocketClient sharedClient];
    NNOAuthCredential *credential = [NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:client.name];
    [client addURL:self.url title:nil withCredential:credential success:^(AFHTTPRequestOperation *operation) {
        [WZNotify showMessage:@"Sent to Pocket" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401) { // unauthorised
            [self authorisePocket];
        } else {
            [WZNotify showMessage:@"Failed sending to Pocket" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
        }
    }];
}

- (void)sendToReadability {
    NNReadabilityClient *client = [NNReadabilityClient sharedClient];
    NNOAuthCredential *credential = [NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:client.name];
    [client addURL:self.url withCredential:credential success:^(AFHTTPRequestOperation *operation) {
        [WZNotify showMessage:@"Sent to Readability" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401) { // unauthorised
            [self showAuthenticateAlertFromWrongPassword:NO];
        } else if (operation.response.statusCode == 409) {
            [WZNotify showMessage:@"Sent to Readability" inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
        }
    }];
}

@end
