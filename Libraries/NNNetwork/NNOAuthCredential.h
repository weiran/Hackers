//
//  NNOAuthCredential.h
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
 `NNOAuthCredential` provides a way to store OAuth credential information. It encapsulates the information needed to authenticate a user.
 
 ### NSCoding / NSCopying Conformance
 
 `NNOAuthCredential` is `NSCoding` and `NSCopying` conformant, which allows you to store objects on disk, with Core Data, and copy them in memory.
 
 ### Storing Information in Keychain
 
 `NNOAuthCredential` provides methods for saving to, retrieving from and deleting from keychain. This functionality is only possible if `[SSKeychain](https://github.com/soffes/sskeychain)` is included with the project.
 */
@interface NNOAuthCredential : NSObject <NSCoding, NSCopying> {
    @private
    NSString *_accessToken;
    NSString *_accessSecret;
    NSString *_refreshToken;
    NSDate *_expirationDate;
    NSDictionary *_userInfo; // Objects and keys in dictionary should be NSCoding conformant.
}

///--------------------------------------------------
/// @name Initializing and Creating OAuth Credentials
///--------------------------------------------------

/**
 Initializes a newly allocated credential with provided access token and access secret.
 
 @param token Credential access token, obtained from an OAuth service. May not be `nil`.
 @param secret Credential access secret, obtained from an OAuth service. May not be `nil`.
 
 @return An initialized `NNOAuthCredential` object.
 */
- (id)initWithAccessToken:(NSString *)token accessSecret:(NSString *)secret;

/**
 Initializes a newly allocated credential with provided access token, access secret and user information.
 
 @param token Credential access token, obtained from an OAuth service. May not be `nil`.
 @param secret Credential access secret, obtained from an OAuth service. May not be `nil`.
 @param userInfo The user information dictionary for the newly allocated credential. Keys and object in this dictionary should be `NSCoding` conformant. May be `nil`.
 
 @return An initialized `NNOAuthCredential` object.
 */
- (id)initWithAccessToken:(NSString *)token accessSecret:(NSString *)secret userInfo:(NSDictionary *)userInfo;

/**
 Creates and returns a new credential with provided access token and access secret.
 
 @param token Credential access token, obtained from an OAuth service. May not be `nil`.
 @param secret Credential access secret, obtained from an OAuth service. May not be `nil`.
 
 @return A new `NNOAuthCredential` object.
 */
+ (id)credentialWithAccessToken:(NSString *)token accessSecret:(NSString *)secret;

/**
 Creates and returns a new credential with provided access token, access secret and user information.
 
 @param token Credential access token, obtained from an OAuth service. May not be `nil`.
 @param secret Credential access secret, obtained from an OAuth service. May not be `nil`.
 @param userInfo The user information dictionary for the new credential. May be `nil`.
 
 @return A new `NNOAuthCredential` object.
 */
+ (id)credentialWithAccessToken:(NSString *)token accessSecret:(NSString *)secret userInfo:(NSDictionary *)userInfo;

/**
 Creates and returns a new credential that has `accessToken` and `accessSecret` set to empty string. 
 
 @return A new empty `NNOAuthCredential` object.
 */
+ (id)emptyCredential;

///--------------------------------------------
/// @name Accessing OAuth Credential Properties
///--------------------------------------------

/**
 Access token for credential.
 
 @discussion If you plan to use a credential with a `NNOAuthClient` instance, this value should not be nil. If you do not have an access token, you should set it to an empty string.
 */
@property(copy, readonly, nonatomic) NSString *accessToken;

/**
 Access secret for credential.
 
  @discussion If you plan to use a credential with a `NNOAuthClient` instance, this value should not be nil. If you do not have an access secret, you should set it to an empty string.
 */
@property(copy, readonly, nonatomic) NSString *accessSecret;

/**
 Refresh token for credential.
 */
@property(copy, nonatomic) NSString *refreshToken;

/**
 Expiration date for credential.
 */
@property(copy, nonatomic) NSDate *expirationDate;

/**
 Checks credential's `expirationDate` and compares it to current date to see if credential is expired.
 
 @return `YES` if credential is expired, otherwise `NO`. If there is no expiration date set, it defaults to `YES`.
 */
- (BOOL)isExpired;

/**
 Returns the user information dictionary associated with credential. It stores any additional data that was provided on initialization.
 
 @return Returns the user information dictionary associated with the receiver. May be `nil`.
 */
- (NSDictionary *)userInfo;

///-----------------------
/// @name Keychain Storage
///-----------------------

/**
 Creates and returns a new credential from keychain for provided service and account.
 
 @param service Service to retrieve credential for.
 @param account Account to retrieve credential for.
 
 @return A new `NNOAuthCredential` object. May be `nil`.
 
 @warning This method relies on `[SSKeychain](https://github.com/soffes/sskeychain)` for keychain interaction. If `SSKeychain` is not present in your project and you attempt to call this method, it will raise an exception.
 */
+ (id)credentialFromKeychainForService:(NSString *)service account:(NSString *)account;

/**
 Saves `NNOAuthCredential` object to keychain for desired service and account.
 
 @param service Service to save credential for.
 @param account Account to save credential for.
 
 @warning This method relies on `[SSKeychain](https://github.com/soffes/sskeychain)` for keychain interaction. If `SSKeychain` is not present in your project and you attempt to call this method, it will raise an exception. This method also relies on `NSCoding` protocol to encode credential data for writing to keychain. If you are using any additional data in `userInfo` dictionary, ensure that it is also `NSCoding` conformant.
 */
- (void)saveToKeychainForService:(NSString *)service account:(NSString *)account;

/**
 Removes `NNOAuthCredential` object from keychain for desired service and account if it exists.
 
 @param service Service to remove credential for.
 @param account Account to remove credential for.
 
 @warning This method relies on `[SSKeychain](https://github.com/soffes/sskeychain)` for keychain interaction. If `SSKeychain` is not present in your project and you attempt to call this method, it will raise an exception.
 */
- (void)removeFromKeychainForService:(NSString *)service account:(NSString *)account;

@end
