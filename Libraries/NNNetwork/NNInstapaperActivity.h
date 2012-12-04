//
//  NNInstapaperActivity.h
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

#import "NNReadLaterActivity.h"
#import "NNInstapaperClient.h"

extern NSString * const NNActivityTypeSendToInstapaper;

/**
 The `NNInstapaperActivity` class provides a way to display an activity for sending a set of URLs to Instapaper. It uses the `sharedClient` from `NNInstapaperClient` class as the base client.
 
 By default, `NNInstapaperActivity` objects display a name, returned by `NNInstapaperClient`, and an image named `NNInstapaperActivity`.
 
 ## Subclassing Notes
 
 This class should almost never be subclassed. The only reason for subclassing `NNInstapaperActivity` is to provide a custom client, image or name for the activity.
 
 ### Methods to Override
 
 You should override the `client` property if you want to use a different client than the `sharedClient` returned by `NNInstapaperClient`.

 You should override `activityName` if you want to display a custom name in the `UIActivityViewController` instance.
 
 You should override `activityImage` if you want to display a custom image in the `UIActivityViewController` instance. 
 */
@interface NNInstapaperActivity : NNReadLaterActivity

///-----------------------------------------------
/// @name Accessing Instapaper Activity Properties
///-----------------------------------------------

/**
 Instapaper client to display activity for.
 */
@property(strong, readonly, nonatomic) NNInstapaperClient *client;

@end

#endif
