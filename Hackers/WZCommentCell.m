//
//  WZCommentCell.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentCell.h"
#import "WZComment.h"

@implementation WZCommentCell

- (void)setComment:(WZComment *)comment {
    _comment = comment;
    [self updateLabels];
}

- (void)updateLabels {
    _userLabel.text = _comment.user;
    _dateLabel.text = _comment.timeAgo;
    _commentLabel.text = _comment.content;
}

@end
