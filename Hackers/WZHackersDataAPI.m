//
//  WZHackersDataAPI.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "WZHackersDataAPI.h"

#import "WZHackersData.h"

static NSString* const baseURL = @"http://node-hnapi.herokuapp.com";
static NSString* const topNewsPath = @"news";
static NSString* const newNewsPath = @"newest";
static NSString* const askNewsPath = @"ask";
static NSString* const commentsPath = @"item";

@implementation WZHackersDataAPI

+ (id)shared {
    static WZHackersDataAPI *__api = nil;
    if (__api == nil) {
        __api = [WZHackersDataAPI new];
    }
    return __api;
}

- (void)fetchNewsOfType:(WZNewsType)type
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure {
    NSString *path = nil;
    
    switch (type) {
        case WZNewsTypeTop:
            path = topNewsPath;
            break;
            
        case WZNewsTypeNew:
            path = newNewsPath;
            break;
            
        case WZNewsTypeAsk:
            path = askNewsPath;
            break;
    }
    
    NSURL *requestURL = [[NSURL URLWithString:baseURL] URLByAppendingPathComponent:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (success) {
                success(JSON);
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            if (failure) {
                failure(error);
            }
        }];
    
    [op start];
}

- (void)fetchCommentsForPost:(NSInteger)postID
                  completion:(void (^)(NSDictionary *items, NSError *error))completion {
    NSURL *requestURL = [[[NSURL URLWithString:baseURL]
                            URLByAppendingPathComponent:commentsPath]
                            URLByAppendingPathComponent:[NSString stringWithFormat:@"%d", postID] isDirectory:NO];
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (completion) {
                completion(JSON, nil);
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            if (completion) {
                completion(nil, error);
            }
        }];
    
    [op start];
}

@end