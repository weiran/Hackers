//
//  WZAccountManager.h
//  Hackers
//
//  Created by Weiran Zhang on 27/04/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZActivityManager : NSObject <UIAlertViewDelegate>

+ (void)setPassword:(NSString *)password forService:(NSString *)service;
+ (NSString *)passwordForService:(NSString *)service;

- (void)sendURL:(NSURL *)url toService:(NSString *)service;
- (void)sendURL:(NSURL *)url title:(NSString *)title toService:(NSString *)service;

@end
