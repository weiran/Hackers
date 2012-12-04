//
//  NSString+NNNetwork.h
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
 The `NSString(NNNetwork)` category extends `NSString` with a set of methods needed for networking.
 */
@interface NSString (NNNetwork)

///-----------------------
/// @name Creating Strings
///-----------------------

/**
 Creates and returns a newly initialized string from an UUID.
 
 @return A new `NSString` object.
 */
+ (id)UUIDString;

///------------------------------------
/// @name Encoding and Decoding Strings
///------------------------------------

/**
 Creates and returns a new URL query encoded string from the receiver.
 
 @return A URL query encoded `NSString` object.
 */
- (NSString *)stringByEncodingForURLQuery;

/**
 Creates and returns a new URL query decoded string from the receiver.
 
 @return A URL query decoded `NSString` object.
 */
- (NSString *)stringByDecodingURLQuery;

/**
 Creates and returns a new base64 encoded string from the receiver.
 
 @return A base64 encoded `NSString` object.
 */
- (NSString *)stringByBase64Encoding;

/**
 Creates and returns a new base64 decoded string from the receiver.
 
 @return A base64 decoded `NSString` object.
 */
- (NSString *)stringByBase64Decoding;

@end
