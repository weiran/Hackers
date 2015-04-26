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

#import "HNComment.h"
#import "HNCommentLink.h"
#import "HNUtilities.h"
#import "HNManager.h"

@implementation HNComment

#pragma mark - Parse Comments
+ (NSArray *)parsedCommentsFromHTML:(NSString *)html forPost:(HNPost *)post {
    // Set Up
    NSMutableArray *comments = [@[] mutableCopy];
    NSString *trash = @"", *upvoteUrl = @"";
    NSDictionary *jsonDict = [[HNManager sharedManager] JSONConfiguration];
    NSDictionary *commentDict = jsonDict && jsonDict[@"Comment"] ? jsonDict[@"Comment"] : nil;
    if (!commentDict) {
        return @[];
    }
    NSArray *htmlComponents = [html componentsSeparatedByString:commentDict[@"CS"] ? commentDict[@"CS"] : @""];
    if (!htmlComponents) {
        return @[];
    }
    
    if (post.Type == PostTypeAskHN) {
        // Grab AskHN Post
        NSScanner *scanner = [NSScanner scannerWithString:htmlComponents[0]];
        NSMutableDictionary *cDict = [NSMutableDictionary new];
        
        // Check for Upvote
        if ([htmlComponents[0] rangeOfString:commentDict[@"Upvote"][@"R"]].location != NSNotFound) {
            [scanner scanBetweenString:commentDict[@"Upvote"][@"S"] andString:commentDict[@"Upvote"][@"S"] intoString:&upvoteUrl];
            upvoteUrl = [upvoteUrl stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        }
        
        for (NSDictionary *dict in commentDict[@"ASK"]) {
            NSString *new = @"";
            BOOL isTrash = [dict[@"I"] isEqualToString:@"TRASH"];
            [scanner scanBetweenString:dict[@"S"] andString:dict[@"E"] intoString:isTrash ? &trash : &new];
            if (new.length > 0) {
                [cDict setObject:new forKey:dict[@"I"]];
            }
        }
        
        // Create special comment for it
        HNComment *newComment = [[HNComment alloc] init];
        newComment.Level = 0;
        newComment.Username = cDict[@"Username"] ? cDict[@"Username"] : @"";
        newComment.TimeCreatedString = cDict[@"Time"] ? cDict[@"Time"] : @"";
        newComment.Text = [HNUtilities stringByReplacingHTMLEntitiesInText:(cDict[@"Text"] ? cDict[@"Text"] : @"")];
        newComment.Links = [HNCommentLink linksFromCommentText:newComment.Text];
        newComment.Type = HNCommentTypeAskHN;
        newComment.UpvoteURLAddition = upvoteUrl.length>0 ? upvoteUrl : nil;
        newComment.CommentId = cDict[@"CommentId"] ? cDict[@"CommentId"] : @"";
        [comments addObject:newComment];
    }
    
    if (post.Type == PostTypeJobs) {
        // Grab Jobs Post
        NSScanner *scanner = [NSScanner scannerWithString:htmlComponents[0]];
        NSMutableDictionary *cDict = [NSMutableDictionary new];
        
        for (NSDictionary *dict in commentDict[@"JOBS"]) {
            NSString *new = @"";
            BOOL isTrash = [dict[@"I"] isEqualToString:@"TRASH"];
            [scanner scanBetweenString:dict[@"S"] andString:dict[@"E"] intoString:isTrash ? &trash : &new];
            if (new.length > 0) {
                [cDict setObject:new forKey:dict[@"I"]];
            }
        }
        
        // Create special comment for it
        HNComment *newComment = [[HNComment alloc] init];
        newComment.Level = 0;
        newComment.Text = [HNUtilities stringByReplacingHTMLEntitiesInText:(cDict[@"Text"] ? cDict[@"Text"] : @"")];
        newComment.Links = [HNCommentLink linksFromCommentText:newComment.Text];
        newComment.Type = HNCommentTypeJobs;
        [comments addObject:newComment];
    }
    
    for (int xx = 1; xx < htmlComponents.count; xx++) {
        // 1st and Last object are garbage.
        if (xx == htmlComponents.count - 1) {
            break;
        }
        
        // Set Up
        NSScanner *scanner = [NSScanner scannerWithString:htmlComponents[xx]];
        HNComment *newComment = [[HNComment alloc] init];
        NSString *upvoteString = @"";
        NSString *downvoteString = @"";
        NSString *level = @"";
        NSMutableDictionary *cDict = [NSMutableDictionary new];
        // Get Comment Level
        [scanner scanBetweenString:commentDict[@"Level"][@"S"] andString:commentDict[@"Level"][@"E"] intoString:&level];
        newComment.Level = [level intValue] / 40;
        
        // If Logged In - Grab Voting Strings
        if ([htmlComponents[xx] rangeOfString:commentDict[@"Upvote"][@"R"]].location != NSNotFound) {
            // Scan Upvote String
            [scanner scanBetweenString:commentDict[@"Upvote"][@"S"] andString:commentDict[@"Upvote"][@"E"] intoString:&upvoteString];
            newComment.UpvoteURLAddition = [upvoteString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            
            // Check for downvote String
            if ([htmlComponents[xx] rangeOfString:commentDict[@"Downvote"][@"R"]].location != NSNotFound) {
                [scanner scanBetweenString:commentDict[@"Downvote"][@"S"] andString:commentDict[@"Downvote"][@"E"] intoString:&downvoteString];
                newComment.DownvoteURLAddition = [downvoteString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            }
        }
        
        for (NSDictionary *dict in commentDict[@"REG"]) {
            NSString *new = @"";
            BOOL isTrash = [dict[@"I"] isEqualToString:@"TRASH"];
            [scanner scanBetweenString:dict[@"S"] andString:dict[@"E"] intoString:isTrash ? &trash : &new];
            if (new.length > 0) {
                [cDict setObject:new forKey:dict[@"I"]];
            }
        }
        
        newComment.CommentId = cDict[@"CommentId"] ? cDict[@"CommentId"] : @"";
        newComment.Username = cDict[@"Username"] ? cDict[@"Username"] : @"";
        newComment.Text = [HNUtilities stringByReplacingHTMLEntitiesInText:(cDict[@"Text"] ? cDict[@"Text"] : @"")];
        newComment.TimeCreatedString = cDict[@"Time"] ? cDict[@"Time"] : @"";
        newComment.ReplyURLString = cDict[@"ReplyUrl"] ? cDict[@"ReplyUrl"] : @"";
        
        // Get Links
        newComment.Links = [HNCommentLink linksFromCommentText:newComment.Text];
        
        // Save Comment
        [comments addObject:newComment];
    }
    
    return comments;
}

@end
