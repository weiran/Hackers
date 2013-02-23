//
//  WZPostModel.m
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "WZPostModel.h"
#import "WZPost.h"

#import "OHAttributedLabel.h"
#import "NSString+AttributedStringForHTML.h"

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
        _content = post.content;
    }
    return self;
}

- (void)setContent:(NSString *)content {
    _content = content;
    _attributedContent = [content attributedStringFromHTML];
}

- (CGFloat)contentHeightForWidth:(CGFloat)width {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_attributedContent));
    CGSize sz = CGSizeMake(0.f, 0.f);
    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
    
    if (framesetter) {
        CFRange fitCFRange = CFRangeMake(0, 0);
        sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, maxSize, &fitCFRange);
        CFRelease(framesetter);
    }
    
    return sz.height;
}

@end
