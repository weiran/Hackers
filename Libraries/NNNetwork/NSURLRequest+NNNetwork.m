//
//  NSURLRequest+NNNetwork.m
//  HackerNews
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

#import "NSURLRequest+NNNetwork.h"
#import "NSString+NNNetwork.h"

@implementation NSURLRequest (NNNetwork)

#pragma mark -
#pragma mark Public Methods

- (NSURLRequest *)requestBySigningForOAuth1WithClientIdentifier:(NSString *)clientIdentifier clientSecret:(NSString *)clientSecret accessToken:(NSString *)accessToken accessSecret:(NSString *)accessSecret signingMethod:(NNOAuthSigningMethod)signingMethod privateKey:(NSData *)privateKey parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [self mutableCopy];
    NSString *authorizationHeader = [NNOAuth authorizationHeaderWithRequestMethod:[request HTTPMethod] requestURL:[request URL] requestParameters:parameters clientIdentifier:clientIdentifier clientSecret:clientSecret accessToken:accessToken accessSecret:accessSecret signingMethod:signingMethod privateKey:privateKey date:[NSDate date] nonce:[NSString UUIDString]];
    [request addValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    return request;
}

@end
