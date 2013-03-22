//
//  WZHackersDataAPI.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#define BACKUP_API_ENDPOINTS @[@"http://node-hnapi.herokuapp.com", @"http://node-hnapi.ap01.aws.af.cm", @"http://node-hnapi-hp.hp.af.cm", @"http://node-hnapi-rs.rs.af.cm", @"http://node-hnapi.azurewebsites.net"]
#define TOP_NEWS_PATH @"news"
#define NEW_NEWS_PATH @"newest"
#define ASK_HN_PATH @"ask"
#define COMMENTS_PATH @"item"

#import <AFNetworking/AFNetworking.h>
#import "WZHackersDataAPI.h"
#import "WZHackersData.h"

@interface WZHackersDataAPI () {
    NSString *_baseURL;
    NSInteger _endpointIndex;
}
@end

@implementation WZHackersDataAPI

+ (id)shared {
    static WZHackersDataAPI *__api = nil;
    if (__api == nil) {
        __api = [WZHackersDataAPI new];
    }
    return __api;
}

- (id)init {
    self = [super init];
    if (self) {
        _endpointIndex = 0;
        _baseURL = [self nextEndpoint];
    }
    return self;
}

- (void)fetchNewsOfType:(WZNewsType)type
                   page:(NSInteger)page
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure {
    NSString *path = nil;
    
    switch (type) {
        case WZNewsTypeTop:
            path = TOP_NEWS_PATH;
            break;
            
        case WZNewsTypeNew:
            path = NEW_NEWS_PATH;
            break;
            
        case WZNewsTypeAsk:
            path = ASK_HN_PATH;
            break;
    }
    
    NSURL *requestURL = [[NSURL URLWithString:_baseURL] URLByAppendingPathComponent:path];
    
    // support 2nd page
    if (page == 2 && type == WZNewsTypeTop) {
        requestURL = [[NSURL URLWithString:_baseURL] URLByAppendingPathComponent:@"news2"];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (success) {
                success(JSON);
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSString *nextEndpoint = [self nextEndpoint];
            if (nextEndpoint) {
                _baseURL = nextEndpoint;
                // if there is another endpoint to try, try it
                [self fetchNewsOfType:type page:page success:success failure:failure];
            } else {
                if (failure) {
                    failure(error);
                }
            }
        }];
    
    [op start];
}

- (void)fetchCommentsForPost:(NSInteger)postID
                  completion:(void (^)(NSDictionary *items, NSError *error))completion {
    NSURL *requestURL = [[[NSURL URLWithString:_baseURL]
                            URLByAppendingPathComponent:COMMENTS_PATH]
                            URLByAppendingPathComponent:[NSString stringWithFormat:@"%d", postID] isDirectory:NO];
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            if (completion) {
                completion(JSON, nil);
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSString *nextEndpoint = [self nextEndpoint];
            if (nextEndpoint) {
                _baseURL = nextEndpoint;
                // if there is another endpoint to try, try it
                [self fetchCommentsForPost:postID completion:completion];
            } else {
                if (completion) {
                    completion(nil, error);
                }
            }
        }];
    
    [op start];
}

- (NSString *)nextEndpoint {
    NSArray *endpoints = BACKUP_API_ENDPOINTS;
    if (_endpointIndex < endpoints.count) {
        return endpoints[_endpointIndex++];
    } else {
        return nil;
    }
}

@end