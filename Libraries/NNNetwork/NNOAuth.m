//
//  NNOAuth.m
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

#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NNOAuth.h"
#import "NSString+NNNetwork.h"
#import "NSData+NNNetwork.h"

NSString * NSStringFromNNOAuthSigningMethod(NNOAuthSigningMethod signingMethod) {
    switch (signingMethod) {
        case NNOAuthSigningMethodHMACSHA1:
            return @"HMAC-SHA1";
        case NNOAuthSigningMethodRSASHA1:
            return @"RSA-SHA1";
        case NNOAuthSigningMethodPLAINTEXT:
            return @"PLAINTEXT";
        default:
            return nil;
    }
}

NSDictionary * NNOAuthParameters(NSString *clientIdentifier, NSString *accessToken, NNOAuthSigningMethod signingMethod, NSDate *date, NSString *nonce) {
    NSMutableDictionary *defaultParameters = [NSMutableDictionary dictionaryWithCapacity:6];
    [defaultParameters setValue:clientIdentifier forKey:@"oauth_consumer_key"];
    [defaultParameters setValue:nonce forKey:@"oauth_nonce"];
    [defaultParameters setValue:NSStringFromNNOAuthSigningMethod(signingMethod) forKey:@"oauth_signature_method"];
    [defaultParameters setValue:[NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]] forKey:@"oauth_timestamp"];
    [defaultParameters setValue:accessToken forKey:@"oauth_token"];
    [defaultParameters setValue:@"1.0" forKey:@"oauth_version"];
    return defaultParameters;
}

NSString * NNOAuthSigningKey(NSString *clientSecret, NSString *accessSecret) {
    if (accessSecret) {
        return [NSString stringWithFormat:@"%@&%@", [clientSecret stringByEncodingForURLQuery], [accessSecret stringByEncodingForURLQuery]];
    }
    return [NSString stringWithFormat:@"%@&", [clientSecret stringByEncodingForURLQuery]];
}

NSString * NNOAuthSignatureBase(NSString *method, NSURL *baseURL, NSDictionary *parameters, NSString *signingKey) {
    // Create a sorted array and normalized parameter string from dictionary of OAuth parameters.
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:[parameters count]];
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSString *encodedKey = [key stringByEncodingForURLQuery];
        NSString *encodedValue = [[value description] stringByEncodingForURLQuery];
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }];
    NSArray *sortedPairs = [pairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    return [[NSString alloc] initWithFormat:@"%@&%@&%@", method, [[baseURL absoluteString] stringByEncodingForURLQuery], [normalizedRequestParameters stringByEncodingForURLQuery]];
}

NSString * NNHMACSHA1Signature(NSString *signingKey, NSString *signatureBase) {
    const char *cKey = [signingKey cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [signatureBase cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMACData = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    return [HMACData stringWithBase64Encoding];
}

NSString * NNRSASHA1Signature(NSData *privateKey, NSString *signatureBase) {
    return nil;
}

#pragma mark -

@implementation NNOAuth

#pragma mark -
#pragma mark Class Methods

+ (NSString *)authorizationHeaderWithRequestMethod:(NSString *)requestMethod requestURL:(NSURL *)requestURL requestParameters:(NSDictionary *)requestParameters clientIdentifier:(NSString *)clientIdentifier clientSecret:(NSString *)clientSecret accessToken:(NSString *)accessToken accessSecret:(NSString *)accessSecret signingMethod:(NNOAuthSigningMethod)signingMethod privateKey:(NSData *)privateKey date:(NSDate *)date nonce:(NSString *)nonce
{
    NSMutableDictionary *authParameters = [NNOAuthParameters(clientIdentifier, accessToken, signingMethod, date, nonce) mutableCopy];
    
    NSString *absoluteString = [[[requestURL absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
    NSURL *baseURL = [NSURL URLWithString:absoluteString];
    
    // Generate signature.
    NSString *signingKey = NNOAuthSigningKey(clientSecret, accessSecret);
    NSString *signature = nil;
    if (signingMethod == NNOAuthSigningMethodPLAINTEXT) {
        signature = signingKey;
    } else {
        // Merge OAuth and request parameters and create a signature with signing key.
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters addEntriesFromDictionary:authParameters];
        [parameters addEntriesFromDictionary:requestParameters];
        NSString *signatureBase = NNOAuthSignatureBase(requestMethod, baseURL, parameters, signingKey);
        if (signingMethod == NNOAuthSigningMethodRSASHA1) {
            signature = NNRSASHA1Signature(privateKey, signatureBase);
        } else {
            signature = NNHMACSHA1Signature(signingKey, signatureBase);
        }
    }
    
    // Add signature to OAuth parameters and generate HTTP Authorization header.
    NSMutableString *header = [NSMutableString stringWithFormat:@"OAuth realm=\"%@\"", [baseURL absoluteString]];
    [authParameters setValue:signature forKey:@"oauth_signature"];
    [authParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *encodedKey = [[key description] stringByEncodingForURLQuery];
        NSString *encodedObj = [[obj description] stringByEncodingForURLQuery];
        [header appendFormat:@", %@=\"%@\"", encodedKey, encodedObj];
    }];
    return header;
}

@end
