//
//  NNOAuth1Client.m
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

#import "NNOAuth1Client.h"

#import "NNOAuthCredential.h"
#import "NSString+NNNetwork.h"
#import "NSData+NNNetwork.h"
#import "NSDictionary+NNNetwork.h"
#import "NSMutableURLRequest+NNNetwork.h"

@implementation NNOAuth1Client

#pragma mark -
#pragma mark NNOAuthClient

- (void)signRequest:(NSMutableURLRequest *)request withParameters:(NSDictionary *)parameters credential:(NNOAuthCredential *)credential
{
    [request signForOAuth1WithClientIdentifier:self.clientIdentifier clientSecret:self.clientSecret accessToken:credential.accessToken accessSecret:credential.accessSecret signingMethod:self.signingMethod privateKey:self.privateKey parameters:parameters];
}

#pragma mark -
#pragma mark Authentication

- (void)temporaryCredentialWithPath:(NSString *)path
                            success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *temporaryCredential))success
                            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{    
    [self signedPostPath:path parameters:nil credential:[NNOAuthCredential credentialWithAccessToken:@"" accessSecret:@""] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseBody = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSDictionary dictionaryWithURLParameterString:responseBody];
        NSString *requestToken = [responseDictionary valueForKey:@"oauth_token"];
        NSString *requestSecret = [responseDictionary valueForKey:@"oauth_token_secret"];
        if (success) {
            success(operation, [NNOAuthCredential credentialWithAccessToken:requestToken accessSecret:requestSecret]);
        }
    } failure:failure];
}

- (void)credentialWithPath:(NSString *)path
       temporaryCredential:(NNOAuthCredential *)temporaryCredential
                  verifier:(NSString *)verifier
                   success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *credential))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self signedPostPath:path parameters:[NSDictionary dictionaryWithObject:verifier forKey:@"oauth_verifier"] credential:temporaryCredential success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseBody = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSDictionary dictionaryWithURLParameterString:responseBody];
        NSString *accessToken = [responseDictionary valueForKey:@"oauth_token"];
        NSString *accessSecret = [responseDictionary valueForKey:@"oauth_token_secret"];
        if (success) {
            success(operation, [NNOAuthCredential credentialWithAccessToken:accessToken accessSecret:accessSecret]);
        }
    } failure:failure];
}

- (void)credentialWithPath:(NSString *)path username:(NSString *)username password:(NSString *)password
                   success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *credential))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                username, @"x_auth_username",
                                password, @"x_auth_password",
                                @"client_auth", @"x_auth_mode", nil];
    [self signedPostPath:path parameters:parameters credential:[NNOAuthCredential emptyCredential] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSString *responseBody = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSDictionary *responseDictionary = [NSDictionary dictionaryWithURLParameterString:responseBody];
            NSString *accessToken = [responseDictionary valueForKey:@"oauth_token"];
            NSString *accessSecret = [responseDictionary valueForKey:@"oauth_token_secret"];
            success(operation, [NNOAuthCredential credentialWithAccessToken:accessToken accessSecret:accessSecret]);
        }
    } failure:failure];
}

@end
