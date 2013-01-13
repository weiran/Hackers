//
//  WZCommentCell.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import <RTLabel.h>

@interface WZCommentCell ()
@property (nonatomic, strong) NSLayoutConstraint *userConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bodyConstraint;
@property (nonatomic, strong) NSLayoutConstraint *repliesConstraint;
@end

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

- (void)setupConstraints {
    NSInteger levelValue = _comment.level.integerValue + 1;
    NSInteger constant = levelValue * 10;
    
    if (_userConstraint) {
        _userConstraint.constant = constant;
    } else {
        NSString *userVisualFormat = [NSString stringWithFormat:@"|-%d-[_userLabel]", constant];
        
        _userConstraint = [NSLayoutConstraint constraintsWithVisualFormat:userVisualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_userLabel)][0];
        [self addConstraint:_userConstraint];
    }
    
    if (_bodyConstraint) {
        _bodyConstraint.constant = constant;
    } else {
        NSString *bodyVisualFormat = [NSString stringWithFormat:@"|-%d-[_commentLabel]", constant];
        
        _bodyConstraint = [NSLayoutConstraint constraintsWithVisualFormat:bodyVisualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_commentLabel)][0];
        [self addConstraint:_bodyConstraint];
    }
    
    if (_repliesConstraint) {
        _repliesConstraint.constant = constant;
    } else {
        NSString *repliesVisualFormat = [NSString stringWithFormat:@"|-%d-[_showRepliesButton]", levelValue * 10];
        
        _repliesConstraint = [NSLayoutConstraint constraintsWithVisualFormat:repliesVisualFormat
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_showRepliesButton)][0];
        [self addConstraint:_repliesConstraint];
    }
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
    
    [self setupConstraints];
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
