// Copyright (C) 2013 by Benjamin Gordon
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and
// associated documentation files (the "Software"), to
// deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "HNPost.h"
#import "HNUtilities.h"
#import "HNManager.h"

@implementation HNPost

#pragma mark - Parse Posts
+ (NSArray *)parsedPostsFromHTML:(NSString *)html FNID:(NSString *__autoreleasing *)fnid {
    // Set up
    NSArray *htmlComponents;
    NSMutableArray *postArray = [NSMutableArray array];
    NSDictionary *jsonDict = [[HNManager sharedManager] JSONConfiguration];
    NSDictionary *posts = jsonDict && jsonDict[@"Post"] ? jsonDict[@"Post"] : nil;
    if (posts) {
        htmlComponents = posts[@"CS"] ? [html componentsSeparatedByString:posts[@"CS"]] : nil;
    }
    else {
        return @[];
    }
    
    
    // Scan through components and build posts
    for (int xx = 1; xx < htmlComponents.count; xx++) {
        // If it's Dead - move past it
        if ([htmlComponents[xx] rangeOfString:@"<td class=\"title\"> [dead] <a"].location != NSNotFound) {
            continue;
        }
        
        // Create new Post
        HNPost *newPost = [[HNPost alloc] init];
        
        // Set Up for Scanning
        NSMutableDictionary *postDict = [NSMutableDictionary new];
        NSScanner *scanner = [[NSScanner alloc] initWithString:htmlComponents[xx]];
        NSString *trash = @"";
        NSString *upvoteString = @"";
        
        // Scan for Upvotes
        if ([htmlComponents[xx] rangeOfString:posts[@"Vote"][@"R"]].location != NSNotFound) {
            [scanner scanBetweenString:posts[@"Vote"][@"S"] andString:posts[@"Vote"][@"E"] intoString:&upvoteString];
            newPost.UpvoteURLAddition = upvoteString;
        }
        
        // Scan from JSON Configuration
        for (NSDictionary *part in posts[@"Parts"]) {
            NSString *new = @"";
            BOOL isTrash = [part[@"I"] isEqualToString:@"TRASH"];
            [scanner scanBetweenString:part[@"S"] andString:part[@"E"] intoString:isTrash ? &trash : &new];
            if (new.length > 0) {
                [postDict setObject:new forKey:part[@"I"]];
            }
        }
        
        // Set Values
        newPost.UrlString = postDict[@"UrlString"] ? postDict[@"UrlString"] : @"";
        newPost.Title = postDict[@"Title"] ? postDict[@"Title"] : @"";
        newPost.Points = postDict[@"Points"] ? [postDict[@"Points"] intValue] : 0;
        newPost.Username = postDict[@"Username"] ? postDict[@"Username"] : @"";
        newPost.PostId = postDict[@"PostId"] ? postDict[@"PostId"] : @"";
        newPost.TimeCreatedString = postDict[@"Time"] ? postDict[@"Time"] : @"";
        
        
        if (postDict[@"Comments"] && [postDict[@"Comments"] isEqualToString:@"discuss"]) {
            newPost.CommentCount = 0;
        }
        else if (postDict[@"Comments"]) {
            NSScanner *cScan = [[NSScanner alloc] initWithString:postDict[@"Comments"] ];
            NSString *cCount = @"";
            [cScan scanUpToString:@" " intoString:&cCount];
            newPost.CommentCount = [cCount intValue];
        }
        
        // Check if Jobs Post
        if (newPost.PostId.length == 0 && newPost.Points == 0 && newPost.Username.length == 0) {
            newPost.Type = PostTypeJobs;
            if ([newPost.UrlString rangeOfString:@"http"].location == NSNotFound) {
                newPost.PostId = [newPost.UrlString stringByReplacingOccurrencesOfString:@"item?id=" withString:@""];
            }
        }
        else {
            // Check if AskHN
            if ([newPost.UrlString rangeOfString:@"http"].location == NSNotFound && newPost.PostId.length > 0) {
                newPost.Type = PostTypeAskHN;
                newPost.UrlString = [@"https://news.ycombinator.com/" stringByAppendingString:newPost.UrlString];
            }
            else {
                newPost.Type = PostTypeDefault;
            }
        }
        
        
        // Grab FNID if last
        if (xx == htmlComponents.count - 1) {
            [scanner scanUpToString:@"<td class=\"title\"><a href=\"" intoString:&trash];
            NSString *Fnid = @"";
            [scanner scanString:@"<td class=\"title\"><a href=\"" intoString:&trash];
            [scanner scanUpToString:@"\"" intoString:&Fnid];
            *fnid = [Fnid stringByReplacingOccurrencesOfString:@"/" withString:@""];
            *fnid = [*fnid stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        }
        
        [postArray addObject:newPost];
    }
    
    return postArray;
}

- (NSString *)UrlDomain {
    NSString *urlDomain = nil;
    
    if (self.UrlString) {
        NSURL *url = [NSURL URLWithString:self.UrlString];
        urlDomain = [url host];
        if ([urlDomain hasPrefix:@"www."]) {
            urlDomain = [urlDomain substringFromIndex:4];
        }
    }
    
    return urlDomain;
}

@end
