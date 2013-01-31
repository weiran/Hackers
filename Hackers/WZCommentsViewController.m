//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <TSMiniWebBrowser.h>
#import <OHAttributedLabel/OHAttributedLabel.h>

#import "NNNetwork.h"
#import "TUSafariActivity.h"

#import "WZCommentsViewController.h"
#import "WZMainViewController.h"
#import "WZHackersDataAPI.h"
#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import "WZPost.h"

@interface WZCommentsViewController ()
- (IBAction)backButtonTapped:(id)sender;
@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-bg-highlighted.png"]
                                                  forBarMetrics:UIBarMetricsDefault];
    [self setupTableView];
    [self fetchComments];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self updateNavigationBarBackground];
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

- (void)setupTableView {
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self layoutTableViewHeader];
    [self layoutTableViewBackgrounds];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPost:)];
    [_headerView addGestureRecognizer:tapGestureRecognizer];
}

- (void)layoutTableViewHeader {
    _headerDomainLabel.text = _post.domain;
    _headerMetadata1Label.text = [NSString stringWithFormat:@"%@ points by %@", _post.points, _post.user];
    _headerMetadata2Label.text = [NSString stringWithFormat:@"%@ · %@ comments", _post.timeAgo, _post.commentsCount];
    _headerTitleLabel.text = _post.title;
    
    CGSize titleLabelSize = [_post.title sizeWithFont:[UIFont fontWithName:@"Futura" size:15]
                                    constrainedToSize:CGSizeMake(301, CGFLOAT_MAX)
                                        lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat height = MAX(titleLabelSize.height, 21);
    CGRect headerViewFrame = _headerView.frame;
    headerViewFrame.size.height = height + 54;
    _headerView.frame = headerViewFrame;
    
    // err, fixes some kinda bug
    _tableView.tableHeaderView = _tableView.tableHeaderView;
}

- (void)layoutTableViewBackgrounds {
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, -480, 320, 480)];
    topView.backgroundColor = [UIColor lightGrayColor];
    [_tableView addSubview:topView];
    
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 1000)];
    footerView.backgroundColor = [UIColor lightGrayColor];
    footerView.opaque = YES;
    [_tableView.tableFooterView addSubview:footerView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    NSString *cellIdentifier = @"CommentCell";
    
    WZCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.linkDelegate = self;
    
    cell.userLabel.text = comment.user;
    cell.dateLabel.text = comment.timeAgo;
    cell.contentIndent = [comment indentPoints];
    cell.commentLabel.attributedText = comment.attributedContent;
    
    if (comment.comments.count > 0) {
        cell.delegate = self;
        cell.showRepliesButton.hidden = NO;
        [cell.showRepliesButton setTitle:[self commentButtonLabelTextWithCount:comment.comments.count expanded:comment.expanded] forState:UIControlStateNormal];
    } else {
        cell.delegate = nil;
        cell.showRepliesButton.hidden = YES;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZCommentModel *comment = _comments[indexPath.row];
    
    return comment.cellHeight.floatValue;
}

#pragma mark - WZCommentURLTappedDelegate

- (void)tappedLink:(NSURL *)url {
    TSMiniWebBrowser *webBrowserViewController = [[TSMiniWebBrowser alloc] initWithUrl:url];
    webBrowserViewController.delegate = self;
    webBrowserViewController.mode = TSMiniWebBrowserModeModal;
    webBrowserViewController.modalDismissButtonTitle = @"Close";
    webBrowserViewController.barTintColor = [UIColor colorWithWhite:0.95 alpha:1];    
    [self presentViewController:webBrowserViewController animated:YES completion:nil];
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
    
    [cell.showRepliesButton setTitle:[self commentButtonLabelTextWithCount:comment.comments.count expanded:comment.expanded]
                            forState:UIControlStateNormal];
}

- (NSString *)commentButtonLabelTextWithCount:(NSUInteger)count expanded:(BOOL)expanded {
    if (count > 1) {
        return [NSString stringWithFormat:@"%@ %d replies", expanded ? @"Hide" : @"Show", count];
    } else {
        return [NSString stringWithFormat:@"%@ 1 reply", expanded ? @"Hide" : @"Show"];
    }
}

- (IBAction)showPost:(id)sender {
    _headerView.backgroundColor = [UIColor lightGrayColor];
    [self tappedLink:[NSURL URLWithString:_post.url]];
}

#pragma mark - TSMiniWebBrowserDelegate

- (void)tsMiniWebBrowserDidDismiss {
    [UIView animateWithDuration:0.5 animations:^{
        _headerView.backgroundColor = [UIColor colorWithWhite:0.87 alpha:1];
    }];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-bg-highlighted.png"]
                                                  forBarMetrics:UIBarMetricsDefault];
}

- (void)updateNavigationBarBackground {
    UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
    if ([navigationController.viewControllers[0] isKindOfClass:[WZMainViewController class]]) {
        WZMainViewController *mainViewController = (WZMainViewController *)self.navigationController.viewControllers[0];
        [mainViewController updateNavigationBarBackground];
    }
}

- (IBAction)showActivityView:(id)sender {
    [[NNInstapaperClient sharedClient] setClientIdentifier:@"JhxaIHH9KhRc3Mj2JaiJ6bYOhMR5Kv7sdeESoBgxlEf51YOdtb"];
    [[NNInstapaperClient sharedClient] setClientSecret:@"Yl6nzC2cVu2AGm8XrqoTt8QgVI0FJs0ndsV5jWbSN7bI3tBSb1"];
    NNOAuthCredential *credential = [NNOAuthCredential credentialWithAccessToken:@"user-token" accessSecret:@"user-secret"];
    NNInstapaperActivity *activity = [[NNInstapaperActivity alloc] initWithCredential:credential];
    
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:_post.url]]
                                                                                         applicationActivities:@[safariActivity, activity]];
    [self presentViewController:activityViewController animated:YES completion:nil];
}
- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
