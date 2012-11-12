//
//  WZCommentModel.m
//  Hackers
//
//  Created by Weiran Zhang on 09/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentModel.h"
#import "NSDictionary+ObjectForKeyOrNil.h"

@implementation WZCommentModel

- (void)updateAttributes:(NSDictionary *)attributes {
    self.content = [attributes objectForKeyOrNil:@"content"];
    self.id = [attributes objectForKeyOrNil:@"id"];
    self.level = [attributes objectForKeyOrNil:@"level"];
    self.timeAgo = [attributes objectForKeyOrNil:@"time_ago"];
    self.user = [attributes objectForKeyOrNil:@"user"];
    NSDictionary *comments = [attributes objectForKeyOrNil:@"comments"];
    
    if (comments) {
        NSMutableArray *newComments = [NSMutableArray array];
        for (NSDictionary *commentDictionary in comments) {
            WZCommentModel *comment = [[WZCommentModel alloc] init];
            [comment updateAttributes:commentDictionary];
            
            if ([comment.content hasPrefix:@"<p>"]) {
                comment.content = [comment.content substringFromIndex:3];
            }
            
            [newComments addObject:comment];
        }
        _comments = newComments;
    }
}

@end
