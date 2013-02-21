//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <QuartzCore/QuartzCore.h>
#import "SDSegmentedControl.h"

#import "WZCommentsViewController.h"
#import "WZMainViewController.h"
#import "WZActivityViewController.h"
#import "WZHackersDataAPI.h"
#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import "WZPostModel.h"
#import "WZWebViewController.h"

#define kHeaderTitleTopMargin 9
#define kHeaderTitleBottomMargin 44

@interface WZCommentsViewController () <UITableViewDelegate, UITableViewDataSource, WZCommentShowRepliesDelegate, WZCommentURLRequested> {
    BOOL _isNavigatingBack;
}

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)showActivityView:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *navigationView;
@property (weak, nonatomic) UIView *webView;
@property (strong, nonatomic) WZWebViewController *webViewController;

@property (weak, nonatomic) IBOutlet UIView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityIndicatorViewTopSpacing;
@property (weak, nonatomic) IBOutlet SDSegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerDomainLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata1Label;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata2Label;
@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavigationView];
    [self setupActivityIndicatorView];
    [self setupTableView];
    [self setupSegmentedController];
    [self setupWebView];
    [self fetchComments];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_isNavigatingBack) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        _isNavigatingBack = NO;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

- (void)fetchComments {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [WZHackersDataAPI.shared fetchCommentsForPost:_post.id completion:^(NSDictionary *comments, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSMutableArray *newComments = [NSMutableArray array];
        for (NSDictionary *commentDictionary in comments) {
            WZCommentModel *comment = [[WZCommentModel alloc] init];
            [comment updateAttributes:commentDictionary];
                        
            [newComments addObject:comment];
        }
        _comments = newComments;
        _activityIndicatorView.hidden = YES;
        
        if (_segmentedControl.selectedSegmentIndex == 0) {
            _tableView.hidden = NO;
        }
        
        [_tableView reloadData];
    }];
}

#pragma mark - Setup Views

- (void)setupNavigationView {
    _navigationView.layer.masksToBounds = NO;
    _navigationView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    _navigationView.layer.shadowColor = [UIColor blackColor].CGColor;
    _navigationView.layer.shadowOpacity = 0.4f;
    _navigationView.layer.shadowRadius = 2;
    _navigationView.clipsToBounds = NO;
    
    // not set a shadowPath here as the navigation view is never animated or changed,
    // if it needs to be animated, the set the path
    //    CGRect shadowPath = CGRectMake(0, 43, 320, 1);
    //    _navigationView.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
}

- (void)setupActivityIndicatorView {
    [self.view bringSubviewToFront:_activityIndicatorView];
}

- (void)setupSegmentedController {
    SDSegmentView *segmenteViewAppearance = [SDSegmentView appearance];
    [segmenteViewAppearance setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [segmenteViewAppearance setTitleShadowColor:[UIColor clearColor] forState:UIControlStateSelected];
    [segmenteViewAppearance setTitleShadowColor:[UIColor clearColor] forState:UIControlStateDisabled];
    // setFont: is deprecated however titleLabel.font property doesn't seem work
    [segmenteViewAppearance setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:14]];
    segmenteViewAppearance.titleEdgeInsets = UIEdgeInsetsMake(5, 0, 0, -8);
    
    SDStainView *stainViewAppearance = [SDStainView appearance];
    stainViewAppearance.shadowColor = [UIColor clearColor];
    stainViewAppearance.shadowOffset = CGSizeMake(0, 0);
    stainViewAppearance.layer.shadowOpacity = 0;
    stainViewAppearance.layer.shadowRadius = 0;
    stainViewAppearance.innerStrokeColor = [UIColor clearColor];
    stainViewAppearance.innerStrokeLineWidth = 0;
    
    _segmentedControl.backgroundColor = [UIColor clearColor];
    _segmentedControl.borderColor = [UIColor clearColor];
    _segmentedControl.arrowHeightFactor = 0;
    
    SDSegmentedControl *segmentedControlAppearence = [SDSegmentedControl appearance];
    segmentedControlAppearence.borderColor = [UIColor clearColor];
    _segmentedControl.borderColor = [UIColor clearColor];
    _segmentedControl.layer.shadowOpacity = 0;
    _segmentedControl.layer.shadowRadius = 0;
    
    [_segmentedControl addTarget:self action:@selector(segmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupTableView {
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self layoutTableViewHeader];
    [self layoutTableViewBackgrounds];
}

- (void)setupWebView {
    _webViewController = [[WZWebViewController alloc] init];
    _webViewController.navigationBarHidden = YES;
    [_webViewController didMoveToParentViewController:self];
    _webView = _webViewController.view;
    _webView.hidden = YES;
    
    _webView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:_webViewController];
    [self.view insertSubview:_webView belowSubview:_navigationView];
    
    NSDictionary *viewDictionary = @{ @"webView": _webView };
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[webView(>=416)]"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:viewDictionary][0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"[webView(>=320)]"
                                                                                       options:0
                                                                                       metrics:nil
                                                                                         views:viewDictionary][0];

    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-44-[webView]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:viewDictionary][0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[webView]|"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:viewDictionary][0];
    NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"|[webView]|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:viewDictionary][0];
    [self.view addConstraint:heightConstraint];
    [self.view addConstraint:widthConstraint];
    [self.view addConstraint:topConstraint];
    [self.view addConstraint:bottomConstraint];
    [self.view addConstraint:horizontalConstraint];
}


- (void)layoutTableViewHeader {
    if ([_post.type isEqualToString:@"ask"]) {
        _headerDomainLabel.text = @"Ask Hacker News";
    } else {
        _headerDomainLabel.text = _post.domain;
    }
    _headerMetadata1Label.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)_post.points, _post.user];
    _headerMetadata2Label.text = [NSString stringWithFormat:@"%@ · %lu comments", _post.timeAgo, (unsigned long)_post.commentsCount];
    _headerTitleLabel.text = _post.title;
    
    CGSize titleLabelSize = [_post.title sizeWithFont:[UIFont fontWithName:kTitleFontName size:kTitleFontSize]
                                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)
                                        lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat height = titleLabelSize.height;
    CGRect headerViewFrame = _headerView.frame;
    headerViewFrame.size.height = kHeaderTitleTopMargin + height + kHeaderTitleBottomMargin;
    _headerView.frame = headerViewFrame;
    
    // err, fixes some kinda bug
    _tableView.tableHeaderView = _tableView.tableHeaderView;
    
    _activityIndicatorViewTopSpacing.constant = 44 + (kHeaderTitleTopMargin + height + kHeaderTitleBottomMargin);
}

- (void)layoutTableViewBackgrounds {
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, -480, 320, 480)];
    topView.backgroundColor = [UIColor colorWithWhite:0.87 alpha:1];
    [_tableView addSubview:topView];
}

#pragma mark - UISegmentDelegate

- (void)segmentDidChange:(id)sender {
    switch ([sender selectedSegmentIndex]) {
        case 0: {
            _tableView.hidden = NO;
            _webView.hidden = YES;
            _webViewController.webView.scrollView.scrollsToTop = NO;
            _tableView.scrollsToTop = YES;
        }
        break;
        case 1: {
            _tableView.hidden = YES;
            _webView.hidden = NO;
            _webViewController.webView.scrollView.scrollsToTop = YES;
            _tableView.scrollsToTop = NO;
            _activityIndicatorView.hidden = YES;
            
            if (!_webViewController.webView.request) {
                [_webViewController loadURL:[NSURL URLWithString:_post.url]];
            }
        }
        break;
    }
}

#pragma mark - UITableViewDelegate

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
    WZWebViewController *webViewController = [[WZWebViewController alloc] initWithURL:url];
    webViewController.view.layer.speed = 2.0;
    [self presentViewController:webViewController animated:YES completion:nil];
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

#pragma mark - Action methods

- (IBAction)showActivityView:(id)sender {
    WZActivityViewController *activityViewController = [WZActivityViewController activityViewControllerWithUrl:[NSURL URLWithString:_post.url] text:_post.title];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)backButtonTapped:(id)sender {
    _isNavigatingBack = YES; 
    [self.navigationController popViewControllerAnimated:YES];
}

@end
