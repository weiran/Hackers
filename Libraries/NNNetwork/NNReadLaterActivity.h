//
//  NNReadLaterActivity.h
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

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0

#import <UIKit/UIKit.h>
#import "NNOAuth1Client.h"
#import "NNReadLaterClient.h"

typedef void(^NNReadLaterActivitySuccessBlock)(AFHTTPRequestOperation *, NSURL *);
typedef void(^NNReadLaterActivityFailureBlock)(AFHTTPRequestOperation *, NSError *, NSURL *);

extern NSString * const NNReadLaterActivityType;

/**
 The `NNReadLaterActivity` class is an abstract class that you subclass in order to implement specific read later services. A service takes a number of `NSURL` objects and adds them to the reading list. Activity objects are used in conjunction with a UIActivityViewController object, which is responsible for presenting services to the user.
 
 You should subclass `NNReadLaterActivity` only if you want to provide custom read later services to the user. `NNNetwork` already provides support for Instapaper, Pocket and Readability services, but you can implement your own.
 
 ## Subclassing Notes
 
 This class must be subclassed before it can be used. The job of an activity object is to act on the data provided to it and to provide some meta information that iOS can display to the user. For more complex services, an activity object can also display a custom user interface and use it to gather additional information from the user.
 
 ### Methods to Override
 
 You should consider overriding the `client` property if you want to return a default client for all activity objects, such as a `sharedClient` provided by `NNReadLaterClient` protocol.
 
 `NNReadLaterActivity` displays a title that it obtains from `client`'s `name`parameter. You should override `activityTitle` if you want to change this title.
 
 `NNReadLaterActivity` displays an image with the same name as the subclass you have created. You should override `activityImage` if you want to change this image.
 
 */
@interface NNReadLaterActivity : UIActivity {
    @private
    NNOAuth1Client<NNReadLaterClient> *_client;
    NNOAuthCredential *_credential;
    NSMutableArray *_URLArray;
    NNReadLaterActivitySuccessBlock _successBlock;
    NNReadLaterActivityFailureBlock _failureBlock;
}

///-----------------------------------------------
/// @name Accessing Read Later Activity Properties
///-----------------------------------------------

/**
 Read later client to display activity for.
 */
@property(strong, readonly, nonatomic) NNOAuth1Client<NNReadLaterClient> *client;

/**
 User credential for the user adding the URLs.
 */
@property(strong, readonly, nonatomic) NNOAuthCredential *credential;

/**
 URLs obtained by the activity for adding to reading list.
 */
@property(strong, readonly, nonatomic) NSArray *URLArray;

/**
 Block to be executed when an URL has been successfully added to the reading list. This block has no return type and takes two arguments: an `AFHTTPRequestOperation` object that initiated the request and an URL added to the reading list.
 */
@property(copy, nonatomic) NNReadLaterActivitySuccessBlock successBlock;

/**
 Block to be executed when adding an URL to the reading list has failed. This block has no return type and takes three arguments: an `AFHTTPRequestOperation` object that initiated the request, a `NSError` object describing the error occured and an URL added to the reading list.
 */
@property(copy, nonatomic) NNReadLaterActivityFailureBlock failureBlock;

///-------------------------------------
/// @name Creating Read Later Activities
///-------------------------------------

/**
 Initializes a newly allocated activity with provided user credential to be used.
 
 @param credential Credential for the user adding the URLs. May not be `nil`.
 
 @return An initialized `NNReadLaterActivity` object.
 */
- (id)initWithCredential:(NNOAuthCredential *)credential;

@end

#endif
