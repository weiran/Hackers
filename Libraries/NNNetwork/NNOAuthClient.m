//
//  NNOAuthClient.m
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

#import "NNOAuthClient.h"

@implementation NNOAuthClient
@synthesize clientIdentifier = _clientIdentifier;
@synthesize clientSecret = _clientSecret;
@synthesize signingMethod = _signingMethod;
@synthesize privateKey = _privateKey;

#pragma mark -
#pragma mark Public Methods

- (void)signRequest:(NSMutableURLRequest *)request withParameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential
{
    // Subclasses should implement this method and modify request with signing info.
}

- (NSMutableURLRequest *)signedRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    [self signRequest:request withParameters:parameters credential:credential];
    return request;
}

- (NSMutableURLRequest *)signedMultipartRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential constructingBodyWithBlock:(void (^)(id <AFMultipartFormData>formData))block;
{
    NSMutableURLRequest *request = [self multipartFormRequestWithMethod:method path:path parameters:parameters constructingBodyWithBlock:block];
    [self signRequest:request withParameters:parameters credential:credential];
    return request;
}

- (void)signedGetPath:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self signedRequestWithMethod:@"GET" path:path parameters:parameters credential:credential];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)signedPostPath:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self signedRequestWithMethod:@"POST" path:path parameters:parameters credential:credential];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)signedPutPath:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self signedRequestWithMethod:@"PUT" path:path parameters:parameters credential:credential];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)signedDeletePath:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self signedRequestWithMethod:@"DELETE" path:path parameters:parameters credential:credential];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)signedPatchPath:(NSString *)path parameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self signedRequestWithMethod:@"PATCH" path:path parameters:parameters credential:credential];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (NSURL *)URLWithPath:(NSString *)path
{
    return [NSURL URLWithString:path relativeToURL:self.baseURL];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        _clientIdentifier = [aDecoder decodeObjectForKey:@"clientIdentifier"];
        _clientSecret = [aDecoder decodeObjectForKey:@"clientSecret"];
        _signingMethod = [aDecoder decodeIntegerForKey:@"signingMethod"];
        _privateKey = [aDecoder decodeObjectForKey:@"privateKey"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_clientIdentifier forKey:@"clientIdentifier"];
    [aCoder encodeObject:_clientSecret forKey:@"clientSecret"];
    [aCoder encodeInteger:_signingMethod forKey:@"signingMethod"];
    [aCoder encodeObject:_privateKey forKey:@"privateKey"];
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    NNOAuthClient *client = [self copyWithZone:zone];
    client.clientIdentifier = [_clientIdentifier copyWithZone:zone];
    client.clientSecret = [_clientSecret copyWithZone:zone];
    client.signingMethod = _signingMethod;
    client.privateKey = [_privateKey copyWithZone:zone];
    return client;
}

@end
