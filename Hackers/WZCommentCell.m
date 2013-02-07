//
//  WZCommentCell.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <OHAttributedLabel/OHAttributedLabel.h>
#import "WZCommentCell.h"

@interface WZCommentCell () {
    NSUInteger _indentationPoints;
}
//@property (nonatomic, strong) NSLayoutConstraint *userConstraint;
//@property (nonatomic, strong) NSLayoutConstraint *bodyConstraint;
//@property (nonatomic, strong) NSLayoutConstraint *repliesConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *repliesConstraint;


@end

@implementation WZCommentCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [_showRepliesButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [_showRepliesButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [_showRepliesButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    _commentLabel.delegate = self;
}

- (void)awakeFromNib {
    
}

- (void)setContentIndent:(NSUInteger)contentIndent {
    if (contentIndent != _indentationPoints) {
        _indentationPoints = contentIndent;
        [self setupConstraints];
    }
}

- (NSUInteger)contentIndent {
    return _indentationPoints;
}


- (void)setupConstraints {
    if (_userConstraint) {
        _userConstraint.constant = _indentationPoints;
    } else {
        NSString *userVisualFormat = [NSString stringWithFormat:@"|-%d-[_userLabel]", _indentationPoints];
        
        _userConstraint = [NSLayoutConstraint constraintsWithVisualFormat:userVisualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_userLabel)][0];
        [self.contentView addConstraint:_userConstraint];
    }
    
    if (_bodyConstraint) {
        _bodyConstraint.constant = _indentationPoints;
    } else {
        NSString *bodyVisualFormat = [NSString stringWithFormat:@"|-%d-[_commentLabel]", _indentationPoints];
        
        _bodyConstraint = [NSLayoutConstraint constraintsWithVisualFormat:bodyVisualFormat
                                                                  options:0
                                                                  metrics:nil
                                                                    views:NSDictionaryOfVariableBindings(_commentLabel)][0];
        [self.contentView addConstraint:_bodyConstraint];
    }
    
    if (_repliesConstraint) {
        _repliesConstraint.constant = _indentationPoints;
    } else {
        NSString *repliesVisualFormat = [NSString stringWithFormat:@"|-%d-[_showRepliesButton]", _indentationPoints];
        
        _repliesConstraint = [NSLayoutConstraint constraintsWithVisualFormat:repliesVisualFormat
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_showRepliesButton)][0];
        [self.contentView addConstraint:_repliesConstraint];
    }
}

- (IBAction)showReplies:(id)sender {
    UITableView *tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    
    if ([_delegate respondsToSelector:@selector(selectedCommentAtIndexPath:)]) {
        [_delegate selectedCommentAtIndexPath:indexPath];
    }
}

-(BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo {
    if ([_linkDelegate respondsToSelector:@selector(tappedLink:)]) {
        [_linkDelegate tappedLink:linkInfo.extendedURL];
        return NO;
    }
    
    return YES;
}

@end
