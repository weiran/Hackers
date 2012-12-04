//
//  NSString+NNNetwork.m
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
#import "NSString+NNNetwork.h"
#import "NSData+NNNetwork.h"

@implementation NSString (NNNetwork)

#pragma mark -
#pragma mark Class Methods

+ (id)UUIDString
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0 || __MAC_OS_X_VERSION_MIN_REQUIRED >= __MAC_10_8
    return [[NSUUID UUID] UUIDString];
#else
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef stringRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    CFRelease(UUIDRef);
    return (__bridge_transfer NSString *)stringRef;
#endif
}

#pragma mark -
#pragma mark Public Methods

- (NSString *)stringByEncodingForURLQuery
{
    static NSString * const kNNLegalCharactersToBeEscaped = @"?!@#$^&%*+=,:;'\"`<>()[]{}/\\|~ ";
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, NULL, (__bridge CFStringRef)kNNLegalCharactersToBeEscaped, kCFStringEncodingUTF8);
}

- (NSString *)stringByDecodingURLQuery
{
	return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
}

- (NSString *)stringByBase64Encoding
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data stringWithBase64Encoding];
}

- (NSString *)stringByBase64Decoding
{
    NSData *data = [NSData dataWithBase64EncodedString:self];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
