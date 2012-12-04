//
//  NNOAuth.h
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

#import <Foundation/Foundation.h>

/**
 The signing method used in OAuth authorization header creation.
 
 @const NNOAuthSigningMethodHMACSHA1 A HMAC-SHA1 signing method.
 @const NNOAuthSigningMethodRSASHA1 A RSA-SHA1 signing method.
 @const NNOAuthSigningMethodPLAINTEXT A plain text signing method.
 
 @discussion You select a signing method based on your OAuth provider's requirements when you generate an authorization header with  `authorizationHeaderWithRequestMethod:requestURL:requestParameters:clientIdentifier:clientSecret:accessToken:accessSecret:signingMethod:privateKey:date:nonce:` method.
 */
typedef enum {
    NNOAuthSigningMethodHMACSHA1 = 0,
    NNOAuthSigningMethodRSASHA1,
    NNOAuthSigningMethodPLAINTEXT
} NNOAuthSigningMethod;

/**
 The `NNOAuth` class provides helper methods for generating OAuth authorization headers.
 */
@interface NNOAuth : NSObject

///-------------------------------------
/// @name Creating Authorization Headers
///-------------------------------------

/**
 Creates and returns an authorization header to be used in `Authorization` field of the HTTP request.
 
 @param requestMethod Method of the OAuth request to be used in the header creation.
 @param requestURL OAuth request URL to be used in the header creation.
 @param requestParameters OAuth request parameters to be used in the header creation.
 @param clientIdentifier Client identifier for the OAuth service to be used in the header creation.
 @param clientSecret Client secret for the OAuth service to be used in the header creation.
 @param accessToken User access token for the OAuth service to be used in the header creation.
 @param accessSecret User access secret for the OAuth service to be used in the header creation.
 @param signingMethod Signing method to be used in the header creation. Defaults to HMAC-SHA1.
 @param privateKey The private key to be used for RSA-SHA1 signing method. If you are not using RSA-SHA1, set to `nil`.
 @param date Date to be used in the header creation.
 @param nonce Nonce to be used in the header creation.

 @return A new `NSString` object.
 */
+ (NSString *)authorizationHeaderWithRequestMethod:(NSString *)requestMethod
                                        requestURL:(NSURL *)requestURL
                                 requestParameters:(NSDictionary *)requestParameters
                                  clientIdentifier:(NSString *)clientIdentifier
                                      clientSecret:(NSString *)clientSecret
                                       accessToken:(NSString *)accessToken
                                      accessSecret:(NSString *)accessSecret
                                     signingMethod:(NNOAuthSigningMethod)signingMethod
                                        privateKey:(NSData *)privateKey
                                              date:(NSDate *)date
                                             nonce:(NSString *)nonce;

@end
