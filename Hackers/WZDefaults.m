//
//  WZDefaults.m
//  Hackers
//
//  Created by Weiran Zhang on 07/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZDefaults.h"
#import "NNNetwork.h"
#import "AFNetworking.h"

@implementation WZDefaults

+ (WZAppDelegate *)appDelegate {
    return (WZAppDelegate *)[[UIApplication sharedApplication] delegate];
}

+ (void)setServiceCredentials {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    if (IS_IPAD()) {
        [[NNPocketClient sharedClient] setClientIdentifier:@"17356-f54b9a60d29b8b2dbcccd4db"];
    } else {
        [[NNPocketClient sharedClient] setClientIdentifier:@"17356-bd8f0582f609ce12e4f4d4a8"];
    }
    [[NNPocketClient sharedClient] setScheme:@"pocketapp-hackers"];
    [[NNReadabilityClient sharedClient] setClientIdentifier:@"weiran"];
    [[NNReadabilityClient sharedClient] setClientSecret:@"aMrkgLwbsws8snZMupDWv7KNuzrkhAfv"];
}

@end
