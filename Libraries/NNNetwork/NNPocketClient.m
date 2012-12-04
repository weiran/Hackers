//
//  NNPocketClient.m
//  NNNetwork
//
//  Copyright (c) 2012 Tomaz Nedeljko (http://nedeljko.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "NNPocketClient.h"
#import "NNOAuthCredential.h"

NSString * const NNPocketClientName = @"Pocket";
NSString * const NNPocketClientBaseString = @"https://readitlaterlist.com/v2/";
NSString * const NNPocketClientAuthenticationPath = @"auth";
NSString * const NNPocketClientAddURLPath = @"add";

@implementation NNPocketClient

#pragma mark -
#pragma mark Public Methods

- (void)addURL:(NSURL *)URL title:(NSString *)title withCredential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:5];
    [parameters setValue:self.APIKey forKey:@"apikey"];
    [parameters setValue:credential.accessToken forKey:@"username"];
    [parameters setValue:credential.accessSecret forKey:@"password"];
    [parameters setValue:URL forKey:@"url"];
    [parameters setValue:title forKey:@"title"];
    
    [self postPath:NNPocketClientAddURLPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

#pragma mark -
#pragma mark NNReadLaterClient

+ (id)sharedClient
{
    static NNPocketClient *SharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedClient = [[NNPocketClient alloc] initWithBaseURL:[NSURL URLWithString:NNPocketClientBaseString]];
    });
    return SharedClient;
}

- (NSString *)name
{
    return NNPocketClientName;
}

- (void)credentialWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *, NNOAuthCredential *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:3];
    [parameters setValue:self.APIKey forKey:@"apikey"];
    [parameters setValue:username forKey:@"username"];
    [parameters setValue:password forKey:@"password"];
    
    [self postPath:NNPocketClientAuthenticationPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation, [NNOAuthCredential credentialWithAccessToken:username accessSecret:password]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation, error);
        }
    }];
}

- (void)addURL:(NSURL *)URL withCredential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self addURL:URL title:nil withCredential:credential success:success failure:failure];
}

@end
