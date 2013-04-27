//
//  WZAccountManager.h
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZAccountManager : NSObject <UIAlertViewDelegate>

+ (WZAccountManager *)shared;
+ (void)setPassword:(NSString *)password forService:(NSString *)service;
+ (NSString *)passwordForService:(NSString *)service;

- (void)sendURL:(NSString *)url toService:(NSString *)service;

@end
