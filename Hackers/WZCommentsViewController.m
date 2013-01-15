//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <TSMiniWebBrowser.h>
#import <CoreTextToy/CLinkingCoreTextLabel.h>
#import <CoreTextToy/CMarkupValueTransformer.h>

#import "WZCommentsViewController.h"
#import "WZHackersDataAPI.h"
#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import "WZPost.h"

@interface WZCommentsViewController () {

}

@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.hidden = YES;
    [self fetchComments];
}

- (void)fetchComments {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [WZHackersDataAPI.shared fetchCommentsForPost:_post.id.integerValue completion:^(NSDictionary *comments, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSMutableArray *newComments = [NSMutableArray array];
        for (NSDictionary *commentDictionary in comments) {
            WZCommentModel *comment = [[WZCommentModel alloc] init];
            [comment updateAttributes:commentDictionary];
                        
            [newComments addObject:comment];
        }
        _comments = newComments;
        _tableView.hidden = NO;
        [_activityIndicator stopAnimating];
        _activityIndicator.hidden = YES;
        [_tableView reloadData];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    for (WZCommentModel *model in _comments) {
        model.cellHeight = nil;
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    NSString *cellIdentifier = @"CommentCell";
    
    WZCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.linkDelegate = self;
    //cell.commentLabel.delegate = self; // for opening links
    
    cell.userLabel.text = comment.user;
    cell.dateLabel.text = comment.timeAgo;
    [cell setHTML:comment.content];
    
    if (comment.comments.count > 0) {
        cell.delegate = self;
        cell.showRepliesButton.hidden = NO;
        cell.showRepliesButton.titleLabel.text = [self commentButtonLabelTextWithCount:comment.comments.count expanded:comment.expanded];
    } else {
        cell.delegate = nil;
        cell.showRepliesButton.hidden = YES;
    }
    
    cell.contentIndent = [self indentPointsForComment:comment];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    
    if (!comment.cellHeight) {
        int replyButtonHeight = 30 + 10; // height + spacing
        int labelHeight = [self heightForCommentLabel:comment];
        CGFloat height = labelHeight + 36;
        
//        RTLabel *label = [[RTLabel alloc] initWithFrame:CGRectMake(0, 0, commentWidth, 0)];
//        label.text = comment.content;
//        CGSize optimumSize = [label optimumSize];
//        CGFloat height = optimumSize.height + 36; // 26 points to top, 10 points to bottom

        if (comment.comments.count > 0) {
            height += replyButtonHeight;
        }
        
        comment.cellHeight = @(height);
    }
    
    return comment.cellHeight.floatValue;
}

- (NSUInteger)indentPointsForComment:(WZCommentModel *)comment {
    NSUInteger baseIndentation = 10;
    NSUInteger indentPerLevel = 15;
    NSUInteger indentation = baseIndentation + (indentPerLevel * comment.level.integerValue);
    return indentation;
}

- (CGFloat)heightForCommentLabel:(WZCommentModel *)comment {
    CMarkupValueTransformer *transformer = [[CMarkupValueTransformer alloc] init];
    NSError *transformError = nil;
    NSAttributedString *attributedString = [transformer transformedValue:comment.content error:&transformError];
    if (!transformError) {
        int rootWidth = 300;
        int indentPoints = [self indentPointsForComment:comment];
        int width = (rootWidth + 10) - indentPoints;
        CLinkingCoreTextLabel *label = [[CLinkingCoreTextLabel alloc] init];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont systemFontOfSize:14];
        CGSize size = [label sizeForString:attributedString constrainedToSize:CGSizeMake(width, 0)];
        return size.height;
    } else {
        NSLog(@"Error transforming attributed string.");
        return 0;
    }
}

#pragma mark - WZCommentURLTappedDelegate

- (void)tappedLink:(NSURL *)url {
    TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:url];
    [self.navigationController pushViewController:webBrowser animated:YES];
}

#pragma mark - WZCommentShowRepliesDelegate

- (void)selectedCommentAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    WZCommentCell *cell = (WZCommentCell *)[_tableView cellForRowAtIndexPath:indexPath];
    
    if (comment.comments && !comment.expanded) {
        comment.expanded = YES;
        
        NSMutableArray *newIndexPaths = [NSMutableArray array];
        NSUInteger lastNewRow = indexPath.row + 1;
        
        for (NSUInteger i = lastNewRow; i < comment.comments.count + lastNewRow; i++) {
            WZCommentModel *newComment = comment.comments[i - lastNewRow];
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_comments insertObject:newComment atIndex:i];
            [newIndexPaths addObject:newIndexPath];
        }
        
        [_tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationMiddle];
    } else if (comment.comments && comment.expanded) {
        comment.expanded = NO;
        
        NSMutableArray *newIndexPaths = [NSMutableArray array];
        
        int currentRow = indexPath.row + 1;
        NSMutableArray *commentsToRemove = [NSMutableArray array];
        
        for (int i = currentRow; i < _comments.count; i++) {
            WZCommentModel *currentComment = _comments[i];
            if (currentComment.level.integerValue > comment.level.integerValue) {
                [commentsToRemove addObject:currentComment];
                currentComment.expanded = NO;
                [newIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            } else {
                break;
            }
        }
        
        [_comments removeObjectsInArray:commentsToRemove];
        
        [_tableView deleteRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationMiddle];
    }
    
    cell.showRepliesButton.titleLabel.text = [self commentButtonLabelTextWithCount:comment.comments.count expanded:comment.expanded];
}

- (NSString *)commentButtonLabelTextWithCount:(NSUInteger)count expanded:(BOOL)expanded {
    if (count > 1) {
        return [NSString stringWithFormat:@"%@ %d replies", expanded ? @"Hide" : @"Show", count];
    } else {
        return [NSString stringWithFormat:@"%@ 1 reply", expanded ? @"Hide" : @"Show"];
    }
}

@end
