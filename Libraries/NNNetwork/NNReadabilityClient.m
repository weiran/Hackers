//
//  NNReadabilityClient.m
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

#import "NNReadabilityClient.h"
#import "NNOAuthCredential.h"

NSString * const NNReadabilityClientName = @"Readability";
NSString * const NNReadabilityClientBaseString = @"https://www.readability.com/api/rest/v1/";
NSString * const NNReadabilityClientAuthorizationPath = @"oauth/access_token/";
NSString * const NNReadabilityClientAddURLPath = @"bookmarks";

@implementation NNReadabilityClient

#pragma mark -
#pragma mark NNReadLaterClient

+ (id)sharedClient
{
    static NNReadabilityClient *SharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedClient = [[NNReadabilityClient alloc] initWithBaseURL:[NSURL URLWithString:NNReadabilityClientBaseString]];
    });
    return SharedClient;
}

- (NSString *)name
{
    return NNReadabilityClientName;
}

- (void)credentialWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *, NNOAuthCredential *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self credentialWithPath:NNReadabilityClientAuthorizationPath username:username password:password success:success failure:failure];
}


- (void)addURL:(NSURL *)URL withCredential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self signedPostPath:NNReadabilityClientAddURLPath parameters:@{@"url" : [URL absoluteString]} credential:credential success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation);
        }
    } failure:failure];
}

@end
