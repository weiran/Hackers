//
//  NNNetwork.h
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

#ifndef _NNNETWORK_H
#define _NNNETWORK_H

#import "NSString+NNNetwork.h"
#import "NSData+NNNetwork.h"
#import "NSDictionary+NNNetwork.h"
#import "NSURLRequest+NNNetwork.h"
#import "NSMutableURLRequest+NNNetwork.h"
#import "NNOAuth.h"
#import "NNOAuthCredential.h"

#import "NNOAuthClient.h"
#import "NNOAuth1Client.h"
#import "NNReadLaterClient.h"
#import "NNInstapaperClient.h"
#import "NNPocketClient.h"
#import "NNReadabilityClient.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "NNReadLaterActivity.h"
#import "NNInstapaperActivity.h"
#import "NNPocketActivity.h"
#import "NNReadabilityActivity.h"
#endif

#endif
