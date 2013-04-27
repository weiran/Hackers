//
//  WZHackersDataAPI.h
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WZHackersData.h"

@interface WZHackersDataAPI : NSObject

+ (id)shared;

- (void)fetchNewsOfType:(WZNewsType)type
                   page:(NSInteger)page
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

- (void)fetchCommentsForPost:(NSInteger)postID
                  completion:(void (^)(NSDictionary *items, NSError *error))completion;

// read later (perhaps refactor this into its own class)

- (void)sendToInstapaper:(NSString *)url username:(NSString *)username password:(NSString *)password completion:(void (^)(BOOL success, BOOL invalidCredentials))completion;
@end
