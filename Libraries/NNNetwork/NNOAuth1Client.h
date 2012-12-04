//
//  NNOAuth1Client.h
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

/**
 `NNOAuth1Client` provides a way to communicate with an OAuth 1.0 service. It provides methods for both, a redirection-based and XAuth authorization. It also subclasses `NNOAuthClient` to implement a signing mechanism. For this, it uses the `signForOAuthWithClientIdentifier:clientSecret:method:parameters:credential:` method of `NSMutableURLRequest(NNNetwork)` category.

 ### Authorization Process
 
 `NNOAuth1Client` provides methods for a typical three step redirection-based authorization process with OAuth 1.0. You should generally implement the following approach:
 
 1. Obtain a temporary credential from temporary credential endpoint. Use `temporaryCredentialWithPath:success:failure:`.
 2. Navigate to resource owner authorization endpoint in Safari or a dedicated `UIWebView`. When the user allows your app access to his account, you should capture the user's `oauth_token` and `oauth_verifier`.
 3. Use `credentialWithPath:credential:verifier:success:failure:` to obtain credential from token request endpoint.
 
 If your OAuth service provides an XAuth authorization option, you only need to provide a user with a login form and then obtain a `NNOAuthCredential` object with `credentialWithPath:username:password:success:failure:`.
 
 ### Subclassing Notes

 You should subclass `NNOAuth1Client` as you would `AFHTTPClient`. If your OAuth service requires a specialized authorization or authentication technique, you should also consider overriding other methods.
 
 #### Methods to Override
 
 If you wish to change the authorization mechanism, you should override any of the methods `temporaryCredentialWithPath:success:failure:`, `credentialWithPath:credential:verifier:success:failure:` or `credentialWithPath:credential:verifier:success:failure:`, depending on what part you wish to change.
 
 If you wish to change the authentication mechanism, you should override mehods as described for `NNOAuthClient`.
 */
@interface NNOAuth1Client : NNOAuthClient

///------------------------
/// @name Authorizing Users
///------------------------

/**
 Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the OAuth client’s operation queue. On completion it parses the response and passes a temporary credential to the `success` block parameter. For client to be able to parse the response successfully, `path` should be a valid temporary credential endpoint. To learn more about this, see [The OAuth 1.0 Protocol](http://tools.ietf.org/html/rfc5849).
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. This path should be a valid temporary credential endpoint.
 @param success A block object to be executed when the request operation finishes parsing a temporary credential successfully. This block has no return value and takes two arguments: the created request operation and the temporary credential created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments: the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)temporaryCredentialWithPath:(NSString *)path
                            success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *temporaryCredential))success
                            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the OAuth client’s operation queue. On completion it parses the response and passes a temporary credential to the `success` block parameter. For client to be able to parse the response successfully, `path` should be a valid token request endpoint. To learn more about this, see [The OAuth 1.0 Protocol](http://tools.ietf.org/html/rfc5849).
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. This path should be a valid token request endpoint.
 @param temporaryCredential The temporary credential to be used in obtaining the access credential.
 @param verifier `oauth_verifier` obtained when redirecting to callback URL.
 @param success A block object to be executed when the request operation finishes parsing a token credential successfully. This block has no return value and takes two arguments: the created request operation and the token credential created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments: the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)credentialWithPath:(NSString *)path
       temporaryCredential:(NNOAuthCredential *)temporaryCredential
                  verifier:(NSString *)verifier
                   success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *credential))success
                   failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the OAuth client’s operation queue. This method essentially sends `x_auth_username`, `x_auth_password` and `x_auth_mode` set to `client_mode` to access token request endpoint. On completion it parses the response and passes a temporary credential to the `success` block parameter. For client to be able to parse the response successfully, `path` should be a valid access token request endpoint. To learn more about XAuth, see [The OAuth 1.0 Protocol](http://tools.ietf.org/html/rfc5849).
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. This path should be a valid access token request endpoint.
 @param username Username to be used as the `x_auth_username` parameter.
 @param password Password to be used as the `x_auth_password` parameter.
 @param success A block object to be executed when the request operation finishes parsing a token credential successfully. This block has no return value and takes two arguments: the created request operation and the token credential created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments: the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (void)credentialWithPath:(NSString *)path username:(NSString *)username password:(NSString *)password
                    success:(void (^)(AFHTTPRequestOperation *operation, NNOAuthCredential *credential))success
                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end