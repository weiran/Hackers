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

#import "WZMainViewController.h"

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

- (void)clearNewsWithType:(WZNewsType)type {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:WZPost.entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"postType == %d", type];
    fetchRequest.includesPropertyValues = NO;
    
    NSArray *news = [_context executeFetchRequest:fetchRequest error:nil];
    
    for (NSManagedObject *newsItem in news) {
        [_context deleteObject:newsItem];
    }
    
    [_context save:nil];
}

#pragma mark - Fetch data

- (void)fetchNewsOfType:(WZNewsType)type page:(NSInteger)page completion:(void (^)(NSError *error))completion {
    [WZHackersDataAPI.shared fetchNewsOfType:type page:page success:^(NSArray *posts) {
        if (page <= 1) {
            [self clearNewsWithType:type];
        }
        
        NSManagedObjectContext *context = [self context];
        
        NSInteger count = (page - 1) * 30 + 1;
        
        for (NSDictionary *dictionary in posts) {
            WZPost *post = [WZPost insertInManagedObjectContext:context];
            [post updateAttributes:dictionary];
            post.postType = @(type);
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

- (WZPost *)fetchPostWithID:(NSInteger)postID {
    NSManagedObjectContext *context = [self context];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[WZPost entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %d", postID];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    request.predicate = predicate;
    request.sortDescriptors = @[sortDescriptor];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:nil cacheName:nil];
    NSArray *result = fetchedResultsController.fetchedObjects;
    
    if (result.count > 0) {
        return result[0];
    } else {
        return nil;
    }
}

#pragma mark - Modify data

- (void)addRead:(NSNumber *)id {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSManagedObjectContext *context = [self context];

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

- (void)updatePost:(NSInteger)postID withContent:(NSString *)content {
    NSManagedObjectContext *context = [self context];
    WZPost *post = [self fetchPostWithID:postID];
    if (post) {
        post.content = content;
        [context save:nil];
    }
}

@end
