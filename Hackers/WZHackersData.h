//
//  WZHackersData.h
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZHackersData : NSObject

+ (id)shared;

@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)fetchTopNewsWithCompletion:(void (^)(NSError *error))completion;
- (void)fetchCommentsForPost:(NSUInteger)postID completion:(void (^)(NSError *))completion;

- (void)addRead:(NSNumber *)id;

@end
