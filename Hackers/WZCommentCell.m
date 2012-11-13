//
//  WZCommentCell.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import <RTLabel/RTLabel.h>

@implementation WZCommentCell

- (void)setComment:(WZCommentModel *)comment {
    _comment = comment;
    [self updateLabels];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _commentLabel.text = _comment.content;
    
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [_showRepliesButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_showRepliesButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [_showRepliesButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
}

- (void)updateLabels {
    _userLabel.text = _comment.user;
    _dateLabel.text = _comment.timeAgo;
    _commentLabel.text = _comment.content;
    if (_comment.expanded) {
        [_showRepliesButton setTitle:@"Hide replies" forState:UIControlStateNormal];
    } else {
        [_showRepliesButton setTitle:@"Show replies" forState:UIControlStateNormal];
    }
}

- (IBAction)showReplies:(id)sender {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    
    if ([_delegate respondsToSelector:@selector(selectedComment:atIndexPath:)]) {
        [_delegate selectedComment:_comment atIndexPath:indexPath];
    }
    
    [self updateLabels];
}
@end
