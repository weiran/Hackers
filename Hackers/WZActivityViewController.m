//
//  WZActivityViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZActivityViewController.h"

#import "TUSafariActivity/TUSafariActivity.h"
#import <ARChromeActivity/ARChromeActivity.h>
#import <ARKippsterActivity/ARKippsteractivity.h>
#import "WZInstapaperActivity.h"
#import "WZPinboardActivity.h"
#import "NNNetwork/NNNetwork.h"
#import "NNNetwork/NNOAuth1Credential.h"
#import "WZNotify.h"

@interface WZActivityViewController () <NNReadLaterActivityDelegate> {
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

@implementation WZActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // gesture recognizer to dismiss UIActivityView when tapped outside
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(tapOut:)];
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_tapGestureRecognizer];
}

- (void)viewWillUnload {
    [self.view removeGestureRecognizer:_tapGestureRecognizer];
}

- (void)tapOut:(id)sender {
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    CGPoint point = [tapGestureRecognizer locationInView:self.view];
    
    CGFloat tappableHeight = 0;
    
    for (UIView *view in [self.view.subviews[0] subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            tappableHeight = view.frame.origin.y;
        }
    }
        
    if (point.y <= tappableHeight) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

+ (WZActivityViewController *)activityViewControllerWithUrl:(NSURL *)url text:(NSString *)text {
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    WZInstapaperActivity *instapaperActivity = [[WZInstapaperActivity alloc] init];
    WZPinboardActivity *pinboardActivity = [[WZPinboardActivity alloc] init];
    ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];
    chromeActivity.activityTitle = @"Open in Chrome";
    ARKippsterActivity *kippsterActivity = [[ARKippsterActivity alloc] init];
    kippsterActivity.activityTitle = @"Send to Kippster";
    
    NNOAuthCredential *pocketCredentails = [NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:[[NNPocketClient sharedClient] name]];
    NNPocketActivity *pocketActivity = [[NNPocketActivity alloc] initWithCredential:pocketCredentails];
    
    NNReadabilityActivity *readabilityActivity = [[NNReadabilityActivity alloc] initWithCredential:[NNOAuthCredential credentialFromKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:[[NNReadabilityClient sharedClient] name]]];
    
    NSArray *activities = @[safariActivity, chromeActivity, instapaperActivity, pinboardActivity, pocketActivity, readabilityActivity, kippsterActivity];
    NSArray *activityItems = @[text, url];
    
    WZActivityViewController *activityViewController = [[WZActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
    pocketActivity.delegate = activityViewController;
    readabilityActivity.delegate = activityViewController;
    activityViewController.url = url;
    
    return activityViewController;
}

#pragma mark NNReadLaterActivityDelegate

- (void)readLaterActivityNeedsCredential:(NNReadLaterActivity *)activity {
    id<NNReadLaterClient> client = activity.client;
    if ([client isKindOfClass:[NNPocketClient class]]) {
        NNPocketClient *pocketClient = (NNPocketClient *)client;
        [pocketClient authorizeWithSuccess:^(AFHTTPRequestOperation *operation, NSString *username, NNOAuth2Credential *credential) {
            NNOAuth2Credential *newCredential = [[NNOAuth2Credential alloc] initWithAccessToken:credential.accessToken userInfo:@{ @"AccountName" : username }];
            [newCredential saveToKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:pocketClient.name];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [WZNotify showMessage:NSLocalizedString(@"Couldn't log into Pocket", nil) inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
        }];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Login to %@", activity.client.name]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Login", nil];
        alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
        
        [alertView show];
    }
}

- (void)readLaterActivity:(NNReadLaterActivity *)activity didFinishWithURL:(NSURL *)url operation:(AFHTTPRequestOperation *)operation error:(NSError *)error {
    if (!error) {
        [WZNotify showMessage:[NSString stringWithFormat:@"Sent to %@", activity.client.name]
                       inView:[WZDefaults appDelegate].window.rootViewController.view
                     duration:2.0f];
    } else {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Error Sending to %@", nil), activity.client.name];
        [WZNotify showMessage:title inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];

    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        
        NNReadabilityClient *client = [NNReadabilityClient sharedClient];
        [client credentialWithUsername:username password:password
            success:^(AFHTTPRequestOperation *operation, NNOAuthCredential *credential) {
                NNOAuth1Credential *newCredential = [NNOAuth1Credential credentialWithAccessToken:credential.accessToken
                                                                                    accessSecret:((NNOAuth1Credential *)credential).accessSecret
                                                                                        userInfo:@{ @"AccountName" : client.name }];
                [newCredential saveToKeychainForService:[[NSBundle mainBundle] bundleIdentifier] account:client.name];
                [client addURL:self.url withCredential:newCredential success:^(AFHTTPRequestOperation *operation) {
                    [WZNotify showMessage:[NSString stringWithFormat:@"Sent to %@", @"Readability"]
                                   inView:[WZDefaults appDelegate].window.rootViewController.view
                                 duration:2.0f];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSString *title = [NSString stringWithFormat:@"Error Sending to %@", @"Readability"];
                    [WZNotify showMessage:title inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
                }];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               [WZNotify showMessage:[NSString stringWithFormat:@"Couldn't log into %@", client.name]
                              inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
            }];
    }
}


@end
