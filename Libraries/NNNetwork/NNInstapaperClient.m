//
//  NNInstapaperClient.m
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

#import "NNInstapaperClient.h"
#import "NNOAuthCredential.h"

NSString * const NNInstapaperClientName = @"Instapaper";
NSString * const NNInstapaperClientBaseString = @"https://www.instapaper.com/api/1/";
NSString * const NNInstapaperClientAuthenticationPath = @"oauth/access_token";
NSString * const NNInstapaperClientVerifyCredentialsPath = @"account/verify_credentials";
NSString * const NNInstapaperClientAddBookmarkPath = @"bookmarks/add";

@implementation NNInstapaperClient

#pragma mark -
#pragma mark Public Methods

- (void)addURL:(NSURL *)URL title:(NSString *)title description:(NSString *)description toFolderID:(NSNumber *)folderID resolveFinalURL:(BOOL)resolveFinalURL withCredential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:5];
    [parameters setValue:URL forKey:@"url"];
    [parameters setValue:title forKey:@"title"];
    [parameters setValue:description forKey:@"description"];
    [parameters setValue:folderID forKey:@"folder_id"];
    [parameters setValue:[NSNumber numberWithBool:resolveFinalURL] forKey:@"resolve_final_url"];
    
    [self signedPostPath:NNInstapaperClientAddBookmarkPath parameters:parameters credential:credential success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation);
        }
    } failure:failure];
}

#pragma mark -
#pragma mark NNReadLaterClient

+ (id)sharedClient
{
    static NNInstapaperClient *SharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedClient = [[NNInstapaperClient alloc] initWithBaseURL:[NSURL URLWithString:NNInstapaperClientBaseString]];
    });
    return SharedClient;
}

- (NSString *)name
{
    return NNInstapaperClientName;
}

- (void)credentialWithUsername:(NSString *)username password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *, NNOAuthCredential *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    [self credentialWithPath:NNInstapaperClientAuthenticationPath username:username password:password success:success failure:failure];
}

- (void)addURL:(NSURL *)URL withCredential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self addURL:URL title:nil description:nil toFolderID:nil resolveFinalURL:YES withCredential:credential success:success failure:failure];
}

@end
