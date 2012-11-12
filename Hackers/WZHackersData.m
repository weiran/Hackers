//
//  WZHackersData.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZHackersData.h"
#import "WZHackersDataAPI.h"
#import "WZPost.h"
#import "WZComment.h"
#import "WZRead.h"

@interface WZHackersData ()
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@end

static NSString* const modelName = @"HackersDataModel";

@implementation WZHackersData

@synthesize context = _context;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (id)shared {
    static WZHackersData *__instance = nil;
    if (__instance == nil) {
        __instance = [WZHackersData new];
    }
    return __instance;
}

#pragma mark - Core Data

- (NSManagedObjectContext *)context {
    if (_context == nil) {
        _context = [NSManagedObjectContext new];
        _context.persistentStoreCoordinator = [self persistentStoreCoordinator];
    }
    return _context;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel == nil) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    return _managedObjectModel;
}

- (NSString *)pathToLocalStore {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    //NSString *pathToModel = [[NSBundle mainBundle] pathForResource:modelName ofType:@"mom"];
    NSString *storeFilename = [modelName stringByAppendingPathExtension:@"sqlite"];
    return [documentsDirectory stringByAppendingPathComponent:storeFilename];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator == nil) {
        NSURL *storeURL = [NSURL fileURLWithPath:self.pathToLocalStore];
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSDictionary *options = @{
                                    NSMigratePersistentStoresAutomaticallyOption : @(YES),
                                    NSInferMappingModelAutomaticallyOption: @(YES)
                                };
        
        NSError *error = nil;
        
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:storeURL
                                                            options:options
                                                              error:&error]) {
            NSDictionary *userInfo = @{ NSUnderlyingErrorKey: error };
            NSString *reason = @"Couldn't create persistent store.";
            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                             reason:reason
                                                           userInfo:userInfo];
            @throw exception;
        }
        
        _persistentStoreCoordinator = persistentStoreCoordinator;
    }
    
    return _persistentStoreCoordinator;
}

- (void)resetCoreStorage {
    @try {
        NSError *error = nil;
        NSPersistentStore *store = [self.persistentStoreCoordinator persistentStoreForURL:[NSURL fileURLWithPath:self.pathToLocalStore]];
        
        if ([self.persistentStoreCoordinator removePersistentStore:store error:&error]) {
            [NSFileManager.defaultManager removeItemAtPath:self.pathToLocalStore error:&error];
        }
        
        if (error) {
            NSLog(@"Failed to remove store %@", error.localizedDescription);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to remove store %@", exception.name);
    }
    @finally {
        _persistentStoreCoordinator = nil;
        _managedObjectModel = nil;
        _context = nil;
    }
}

- (void)clearNews {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:WZPost.entityName];
    fetchRequest.includesPropertyValues = NO;
    
    NSArray *news = [_context executeFetchRequest:fetchRequest error:nil];
    
    for (NSManagedObject *newsItem in news) {
        [_context deleteObject:newsItem];
    }
    
    [_context save:nil];
}

#pragma mark - Fetch data

- (void)fetchTopNewsWithCompletion:(void (^)(NSError *error))completion {
    [WZHackersDataAPI.shared fetchNewsWithSuccess:^(NSArray *posts) {
        [self clearNews];
        
        NSManagedObjectContext *context = [NSManagedObjectContext new];
        context.persistentStoreCoordinator = [WZHackersData.shared persistentStoreCoordinator];

        NSInteger count = 1;
        for (NSDictionary *dictionary in posts) {
            WZPost *post = [WZPost insertInManagedObjectContext:context];
            [post updateAttributes:dictionary];
            post.rank = @(count++);
        }
        
        NSError *error = nil;
        if ([context save:&error]) {
            if (completion) {
                completion(nil);
            }
        } else {
            NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0) {
                for(NSError* detailedError in detailedErrors) {
                    NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            } else {
                NSLog(@"  %@", [error userInfo]);
            }

            if (completion) {
                completion(error);
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"Failed to download top news");
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - Modify data

- (void)addRead:(NSNumber *)id {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext *context = [NSManagedObjectContext new];
        context.persistentStoreCoordinator = [WZHackersData.shared persistentStoreCoordinator];

        WZRead *read = [WZRead insertInManagedObjectContext:context];
        read.id = id;
        
        NSError *error = nil;
        
        if (![context save:&error]) {
            NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0) {
                for(NSError* detailedError in detailedErrors) {
                    NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            } else {
                NSLog(@"  %@", [error userInfo]);
            }
        }
    });
}

@end
