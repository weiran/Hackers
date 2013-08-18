//
//  WZCreditsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 18/08/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZCreditsViewController.h"
#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>

#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory.h>
#import <FontAwesomeIconFactory/NIKFontAwesomeIconFactory+iOS.h>
#import "WZNotify.h"
#import "WZButton.h"

@interface WZCreditsViewController ()
@property (nonatomic, strong) MFMailComposeViewController *mailer;
@property (weak, nonatomic) IBOutlet WZButton *rateButton;
@property (weak, nonatomic) IBOutlet WZButton *feedbackButton;
@end

@implementation WZCreditsViewController

- (void)viewDidLoad {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
    [self.rateButton setImage:[factory createImageForIcon:NIKFontAwesomeIconStar] forState:UIControlStateNormal];
    [self.feedbackButton setImage:[factory createImageForIcon:NIKFontAwesomeIconEnvelope] forState:UIControlStateNormal];
}

- (IBAction)rate:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=603503901&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
}

- (IBAction)sendFeedback:(id)sender {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    NSString *revision = infoDictionary[@"CFBundleVersion"];
    
    self.mailer = [[MFMailComposeViewController alloc] init];
    self.mailer.mailComposeDelegate = self;
    [self.mailer setSubject:[NSString stringWithFormat:@"Feedback for Hackers %@ (%@) on %@", version, revision, machineName()]];
    [self.mailer setToRecipients:@[@"weiran@zhang.me.uk"]];
    [self presentViewController:self.mailer animated:YES completion:nil];
}

- (IBAction)viewTwitter:(id)sender {
    NSString *tweetbotUrl = [NSString stringWithFormat:@"tweetbot://%@/user_profile/weiran", @"weiran"];
    NSString *twitterrificUrl = [NSString stringWithFormat:@"twitterrific://current/profile?screen_name=%@", @"weiran"];
    NSString *twitterUrl = @"twitter://user?screen_name=weiran";
    UIApplication *app = [UIApplication sharedApplication];

    if ([app canOpenURL:[NSURL URLWithString:twitterrificUrl]]) {
        [app openURL:[NSURL URLWithString:twitterrificUrl]];
    } else if ([app canOpenURL:[NSURL URLWithString:tweetbotUrl]]) {
        [app openURL:[NSURL URLWithString:tweetbotUrl]];
    } else if ([app canOpenURL:[NSURL URLWithString:twitterUrl]]) {
        [app openURL:[NSURL URLWithString:twitterUrl]];
    } else {
        [app openURL:[NSURL URLWithString:@"https://twitter.com/weiran"]];
    }
}

- (IBAction)viewWebsite:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://weiranzhang.com"]];
}

NSString* machineName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultFailed || error) {
        [WZNotify showMessage:@"Failed sending feedback." inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];

    }
    
    if (result == MFMailComposeResultSent && !error) {
        [WZNotify showMessage:@"Feedback sent. Thanks." inView:[WZDefaults appDelegate].window.rootViewController.view duration:2.0f];
    }
    
    [self.mailer dismissViewControllerAnimated:YES completion:nil];
}

@end
