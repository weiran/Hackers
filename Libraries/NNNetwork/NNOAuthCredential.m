//
//  NNOAuthCredential.m
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

#import "NNOAuthCredential.h"
#import "SSKeychain.h"

@interface NNOAuthCredential ()

@property(copy, readwrite, nonatomic) NSString *accessToken;
@property(copy, readwrite, nonatomic) NSString *accessSecret;

@end

@implementation NNOAuthCredential
@synthesize accessToken = _accessToken;
@synthesize accessSecret = _accessSecret;
@synthesize refreshToken = _refreshToken;
@synthesize expirationDate = _expirationDate;

#pragma mark -
#pragma mark Class Methods

+ (id)emptyCredential
{
    return [[self alloc] initWithAccessToken:@"" accessSecret:@""];
}

+ (id)credentialWithAccessToken:(NSString *)token accessSecret:(NSString *)secret
{
    return [[self alloc] initWithAccessToken:token accessSecret:secret userInfo:nil];
}

+ (id)credentialWithAccessToken:(NSString *)token accessSecret:(NSString *)secret userInfo:(NSDictionary *)userInfo
{
    return [[self alloc] initWithAccessToken:token accessSecret:secret userInfo:userInfo];
}

+ (id)credentialFromKeychainForService:(NSString *)service account:(NSString *)account
{
    NSData *data = [SSKeychain passwordDataForService:service account:account];
    return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

#pragma mark -
#pragma mark Initialization

- (id)initWithAccessToken:(NSString *)token accessSecret:(NSString *)secret
{
    return [self initWithAccessToken:token accessSecret:secret userInfo:nil];
}

- (id)initWithAccessToken:(NSString *)token accessSecret:(NSString *)secret userInfo:(NSDictionary *)userInfo
{
    self = [super init];
    if (self) {
        _accessToken = [token copy];
        _accessSecret = [secret copy];
        _userInfo = [userInfo copy];
    }
    return self;
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)isExpired
{
    return [self.expirationDate compare:[NSDate date]] == NSOrderedAscending;
}

- (NSDictionary *)userInfo
{
    return [_userInfo copy];
}

- (void)saveToKeychainForService:(NSString *)service account:(NSString *)account
{
    NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:self];
    [SSKeychain setPasswordData:credentialData forService:service account:account];
}

- (void)removeFromKeychainForService:(NSString *)service account:(NSString *)account
{
    [SSKeychain deletePasswordForService:service account:account];
}

#pragma mark -
#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ accessToken:\"%@\" accessSecret:\"%@\" refreshToken:\"%@\" expirationDate:\"%@\">", [self class], self.accessToken, self.accessSecret, self.refreshToken, self.expirationDate];
}

#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _accessToken = [decoder decodeObjectForKey:@"accessToken"];
        _accessSecret = [decoder decodeObjectForKey:@"accessSecret"];
        _refreshToken = [decoder decodeObjectForKey:@"refreshToken"];
        _expirationDate = [decoder decodeObjectForKey:@"expirationDate"];
        _userInfo = [decoder decodeObjectForKey:@"userInfo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_accessToken forKey:@"accessToken"];
    [encoder encodeObject:_accessSecret forKey:@"accessSecret"];
    [encoder encodeObject:_refreshToken forKey:@"refreshToken"];
    [encoder encodeObject:_expirationDate forKey:@"expirationDate"];
    [encoder encodeObject:_userInfo forKey:@"userInfo"];
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NNOAuthCredential *credential = [[NNOAuthCredential allocWithZone:zone] initWithAccessToken:self.accessToken accessSecret:self.accessSecret userInfo:[self userInfo]];
    credential.refreshToken = [_refreshToken copyWithZone:zone];
    credential.expirationDate = [_expirationDate copyWithZone:zone];
    return credential;
}

@end
