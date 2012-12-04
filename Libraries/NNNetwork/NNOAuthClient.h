//
//  NNOAuthClient.h
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

#import "AFHTTPClient.h"
#import "NNOAuth.h"

@class NNOAuthCredential;

/**
 `NNOAuthClient` extends `AFHTTPClient` to provide a way for communicating with an OAuth service. It defines a set of methods for creating and sending signed requests. However, `NNOAuthClient` is an abstract class and by itself does not provide a signing mechanism. It should always be used for creating a subclass. `NNNetwork` provides a subclass for interaction with OAuth 1 encapsulated by `NNOAuth1Client`.
 
 ### Subclassing Notes
 
 `NNOAuthClient` should always be subclassed as it doesn't provide a custom signing mechanism. You should create a subclass as recommended for `AFHTTPClient` and implement a custom signing mechanism by overriding appropriate methods.
 
 #### Methods to Override
 
 To change the signing mechanism of `NNOAuthClient`, override `signRequest:withParameters:credential:`.
 
 To change the actual signed requests, override `signedRequestWithMethod:path:parameters:credential:` and `signedMultipartRequestWithMethod:path:parameters:credential:constructingBodyWithBlock:` methods.
 */
@interface NNOAuthClient : AFHTTPClient {
    @private
    NSString *_clientIdentifier;
    NSString *_clientSecret;
    NNOAuthSigningMethod _signingMethod;
    NSData *_privateKey;
}

///----------------------------------------
/// @name Accessing OAuth Client Properties
///----------------------------------------

/**
 Client identifier for the service.
 */
@property(copy, nonatomic) NSString *clientIdentifier;

/**
 Client secret for the service.
 */
@property(copy, nonatomic) NSString *clientSecret;

/**
 OAuth signing method for the service. Defaults to HMAC-SHA1.
 */
@property(nonatomic) NNOAuthSigningMethod signingMethod;

/**
 Private key for RSA-SHA1 signing method if it is the `signingMethod` for the client.
 */
@property(copy, nonatomic) NSData *privateKey;

///-----------------------------
/// @name Signing OAuth Requests
///-----------------------------

/**
 Signs a provided `NSMutableURLRequest` for OAuth with parameters and user credential.
 
 @param request A `NSMutableURLRequest`object to be .
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @param credential The user provided credential.
 
 @discussion This method has to be overriden by subclasses to provide a custom signing mechanism. For examples, you should take a look at `NNOAuth1Client` and `NNOAuth2Client` classes. 
 */
- (void)signRequest:(NSMutableURLRequest *)request
     withParameters:(NSDictionary *)parameters
         credential:(NNOAuthCredential *)credential;

/**
 Creates a `NSMutableURLRequest` object with the specified HTTP method and path and signs it with user provided credential.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @param credential The user provided credential used for signing the request.
 
 @return A `NSMutableURLRequest` object.
 */
- (NSMutableURLRequest *)signedRequestWithMethod:(NSString *)method path:(NSString *)path
                                      parameters:(NSDictionary *)parameters
                                      credential:(NNOAuthCredential *)credential;

/**
 Creates a `NSMutableURLRequest` object with the specified HTTP method and path and signs it with user provided credential, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @param credential The user provided credential used for signing the request.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the AFMultipartFormData protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values. For more information, see `AFHTTPClient`.
 
 @return A `NSMutableURLRequest` object.
 */
- (NSMutableURLRequest *)signedMultipartRequestWithMethod:(NSString *)method path:(NSString *)path
                                               parameters:(NSDictionary *)parameters
                                               credential:(NNOAuthCredential *)credential
                                constructingBodyWithBlock:(void (^)(id <AFMultipartFormData>formData))block;

///----------------------------------
/// @name Making Signed HTTP Requests
///----------------------------------

/**
 Creates an `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the OAuth client’s operation queue.
 
 @param path The path to be appended to the OAuth client’s base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param credential The user provided credential used for signing the request.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @discussion Creates an `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the OAuth client’s operation queue.
 */
- (void)signedGetPath:(NSString *)path
           parameters:(NSDictionary *)parameters
           credential:(NNOAuthCredential *)credential
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the OAuth client’s operation queue.
 
 @param path The path to be appended to the OAuth client’s base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param credential The user provided credential used for signing the request.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @discussion Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the OAuth client’s operation queue.
 */
- (void)signedPostPath:(NSString *)path
            parameters:(NSDictionary *)parameters
            credential:(NNOAuthCredential *)credential
               success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `PUT` request, and enqueues it to the OAuth client’s operation queue.
 
 @param path The path to be appended to the OAuth client’s base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param credential The user provided credential used for signing the request.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @discussion Creates an `AFHTTPRequestOperation` with a `PUT` request, and enqueues it to the OAuth client’s operation queue.
 */
- (void)signedPutPath:(NSString *)path
           parameters:(NSDictionary *)parameters
           credential:(NNOAuthCredential *)credential
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `DELETE` request, and enqueues it to the OAuth client’s operation queue.
 
 @param path The path to be appended to the OAuth client’s base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param credential The user provided credential used for signing the request.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @discussion Creates an `AFHTTPRequestOperation` with a `DELETE` request, and enqueues it to the OAuth client’s operation queue.
 */
- (void)signedDeletePath:(NSString *)path
              parameters:(NSDictionary *)parameters
              credential:(NNOAuthCredential *)credential
                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `PATCH` request, and enqueues it to the OAuth client’s operation queue.
 
 @param path The path to be appended to the OAuth client’s base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param credential The user provided credential used for signing the request.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @discussion Creates an `AFHTTPRequestOperation` with a `PATCH` request, and enqueues it to the OAuth client’s operation queue.
 */
- (void)signedPatchPath:(NSString *)path
             parameters:(NSDictionary *)parameters
             credential:(NNOAuthCredential *)credential
                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates and returns a new `NSURL` objects with path relative o `baseURL`.
 
 @param path The path to be appended to the OAuth client’s base URL.
 */
- (NSURL *)URLWithPath:(NSString *)path;

@end
