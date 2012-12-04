//
//  NSURLRequest+NNNetwork.h
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

#import <Foundation/Foundation.h>
#import "NNOAuth.h"

/**
 The `NSURLRequest(NNNetwork)` category extends `NSURLRequest` with a set of methods needed for networking.
 */
@interface NSURLRequest (NNNetwork)

///---------------------------
/// @name Signing URL Requests
///---------------------------

/**
 Creates a copy of the receiver and signes it for OAuth 1.0 service with provided parameters. This method does not obtain URL parameters from the receiver, but rather requires separate URL parameters to be passed through the `parameters` variable. This may be useful if you need to exclude some URL parameters from request signing.
 
 @param clientIdentifier The client identifier used in the signing process.
 @param clientSecret The client secret used in the signing process.
 @param accessToken The access token used in the signing process.
 @param accessSecret The access secret used in the signing process.
 @param signingMethod The OAuth signing method used in the signing process. May be HMAC-SHA1, RSA-SHA1 or plain text. Defaults to HMAC-SHA1.
 @param privateKey The private key to be used for RSA-SHA1 signing method. If you are not using RSA-SHA1, set to `nil`.
 @param parameters The parameters to be used in the signing process.
 
 @return A new `NSURLRequest` object.
 */
- (NSURLRequest *)requestBySigningForOAuth1WithClientIdentifier:(NSString *)clientIdentifier
                                                   clientSecret:(NSString *)clientSecret
                                                    accessToken:(NSString *)accessToken
                                                   accessSecret:(NSString *)accessSecret
                                                  signingMethod:(NNOAuthSigningMethod)signingMethod
                                                     privateKey:(NSData *)privateKey
                                                     parameters:(NSDictionary *)parameters;

@end
