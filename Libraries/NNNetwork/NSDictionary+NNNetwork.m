//
//  NSDictionary+NNNetwork.m
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

#import "NSDictionary+NNNetwork.h"
#import "NSString+NNNetwork.h"

@implementation NSDictionary (NNNetwork)

#pragma mark -
#pragma mark Class Methods

+ (NSDictionary *)dictionaryWithURLParameterString:(NSString *)parameterString
{
    NSArray *pairs = [parameterString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[pairs count]];
    for (NSString *pair in pairs) {
        NSArray *parts = [pair componentsSeparatedByString:@"="];
        if ([parts count] == 2) {
            NSString *key = [[parts objectAtIndex:0] stringByDecodingURLQuery];
            NSString *value = [[parts objectAtIndex:1] stringByDecodingURLQuery];
            [dictionary setValue:value forKey:key];
        }
    }
    return dictionary;
}

#pragma mark -
#pragma mark Public Methods

- (NSString *)stringByEncodingForURLQuery
{
    NSMutableString *string = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [string appendFormat:@"%@=%@", [[key description] stringByEncodingForURLQuery], [[obj description] stringByEncodingForURLQuery]];
    }];
    return string;
}

@end
