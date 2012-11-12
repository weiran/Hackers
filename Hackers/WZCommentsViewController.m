//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <RTLabel/RTLabel.h>

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
            
            if ([comment.content hasPrefix:@"<p>"]) {
                comment.content = [comment.content substringFromIndex:3];
            }
            
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
    
    switch (comment.level.integerValue) {
        case 1:
            cellIdentifier = @"CommentCellLevel1";
            break;
            
        case 2:
            cellIdentifier = @"CommentCellLevel2";
            break;
        
        case 3:
            cellIdentifier = @"CommentCellLevel3";
            break;
    }
    
    WZCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.comment = comment;
    cell.commentLabel.delegate = self;
    cell.indentationLevel = comment.level.integerValue + 1;
    cell.indentationWidth = 20;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    
    if (!comment.cellHeight) {
        RTLabel *label = [[RTLabel alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 0)];
        label.text = comment.content;
        CGSize optimumSize = [label optimumSize];
        comment.cellHeight = @(optimumSize.height + 36);
    }
    
    return comment.cellHeight.floatValue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
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
        
        [tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - RTLabelDelegate

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL *)url {
    
}

@end
