//
//  NNReadLaterClient.h
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

@class AFHTTPRequestOperation, NNOAuthCredential;

/**
 The `NNReadLaterClient` protocol defines features and functions that are associated with a read later service. All classes that provide access to a read later service should conform to this protocol for consistency. In `NNNetwork` classes that conform to this protocol include `NNInstapaperClient`, `NNPocketClient` and `NNReadabilityClient`.
 */
@protocol NNReadLaterClient <NSObject>

///----------------------------------
/// @name Accessing Read Later Client
///----------------------------------

/**
 Returns the default shared read later client. It is recommended to always use this client, if you only need to work with one instance of the service.
 */
+ (id)sharedClient;

///---------------------------------------------
/// @name Accessing Read Later Client Properties
///---------------------------------------------

/**
 Name of the service.
 */
@property(copy, readonly, nonatomic) NSString *name;

///------------------------------------------
/// @name Interacting with Read Later Service
///------------------------------------------

/**
 Sends a request to the read later service that obtains access credential for the user with specified username and password.
 
 @param username Username for the read later account.
 @param password Password for the read later account.
 @param success A block object to be executed when the request operation finishes parsing a token credential successfully. This block has no return value and takes two arguments: the created request operation and the credential created from the response data of the request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments: the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)credentialWithUsername:(NSString *)username password:(NSString *)password
                       success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *credential))success
                       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Sends a request to the read later service that adds an URL to the reading list of the user with the provided user credential.
 
 @param URL URL to add to the reading list.
 @param credential Credential for the user adding the URL.
 @param success A block object to be executed when the request operation finishes parsing a token credential successfully. This block has no return value and takes the request operation as the argument.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments: the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)addURL:(NSURL *)URL withCredential:(NNOAuthCredential *)credential
       success:(void (^)(AFHTTPRequestOperation *operation))success
       failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
