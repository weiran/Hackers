//
//  WZPostModel.m
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZPostModel.h"
#import "WZPost.h"

@implementation WZPostModel

- (id)initWithPost:(WZPost *)post
{
    self = [super init];
    if (self) {
        _commentsCount = post.commentsCount.integerValue;
        _domain = post.domain;
        _id = post.id.integerValue;
        _points = post.points.integerValue;
        _postType = post.postType.integerValue;
        _rank = post.rank.integerValue;
        _timeAgo = post.timeAgo;
        _title = post.title;
        _type = post.type;
        _url = post.url;
        _user = post.user;
        _cellHeight = post.cellHeight;
        _labelHeight = post.labelHeight;
    }
    return self;
}

@end
