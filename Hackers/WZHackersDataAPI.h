//
//  WZHackersDataAPI.h
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZHackersDataAPI : NSObject

+ (id)shared;

- (void)fetchNewsWithSuccess:(void (^)(NSArray *posts))success
                     failure:(void (^)(NSError *error))failure;

- (void)fetchCommentsForPost:(NSUInteger)postID completion:(void (^)(NSDictionary *comments, NSError *error))completion;

@end
