//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <QuartzCore/QuartzCore.h>
#import <JSSlidingViewController.h>

#import "WZCommentsViewController.h"
#import "WZMainViewController.h"
#import "WZActivityViewController.h"
#import "WZHackersDataAPI.h"
#import "WZHackersData.h"
#import "WZCommentCell.h"
#import "WZCommentModel.h"
#import "WZPostModel.h"
#import "WZWebViewController.h"
#import "WZNavigationController.h"
#import "WZNotify.h"

#define kHeaderTitleTopMargin 10
#define kHeaderTitleBottomMargin 44
#define kHeaderTextBottomMargin 10
#define kHeaderTextWidth 300
#define kNavigationBarHeight 44

@interface WZCommentsViewController () <UITableViewDelegate, UITableViewDataSource, WZCommentShowRepliesDelegate, WZCommentURLRequested, OHAttributedLabelDelegate> {
    BOOL _isNavigatingBack;
}

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)showActivityView:(id)sender;
- (IBAction)headerViewTapped:(id)sender;
- (IBAction)swipedBack:(id)sender;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeBackGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIView *navigationView;
@property (weak, nonatomic) UIView *webView;
@property (strong, nonatomic) WZWebViewController *webViewController;

@property (weak, nonatomic) IBOutlet UIView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityIndicatorViewTopSpacing;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *headerDetailsContainerView;
@property (weak, nonatomic) IBOutlet UILabel *headerTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerDomainLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata1Label;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata2Label;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *headerTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerDetailViewBottomSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerTextViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerTextViewBottomSpacing;
@property (strong, nonatomic) NSLayoutConstraint *webViewTopSpacing;
@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupOrientationNotifications];
    [self setupNavigationView];
    [self setupActivityIndicatorView];
    [self setupTableView];
    [self setupSegmentedController];
    [self setupWebView];
    [self fetchComments];
    [self showDefaultView];
    
    _webViewController.webView.scrollView.scrollsToTop = NO;
    _tableView.scrollsToTop = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // set selected segement colours
    // uses GCD as it wont work if run immediately
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self segmentDidChange:_segmentedControl];
    });
    
    [[[WZDefaults appDelegate] viewController] setLocked:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_isNavigatingBack) {
        [self removeOrientationNotifications];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        _isNavigatingBack = NO;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[[WZDefaults appDelegate] viewController] setLocked:NO];
    }
}

- (void)fetchComments {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [WZHackersDataAPI.shared fetchCommentsForPost:_post.id completion:^(NSDictionary *items, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (error) {
            [WZNotify showMessage:@"Failed getting comments" inView:self.navigationController.view duration:2];
        }
        
        // update post model if content exists
        id content = items[@"content"];
        if (content != [NSNull null]) {
            [[WZHackersData shared] updatePost:_post.id withContent:content];
            _post.content = content;
            [self layoutTableViewHeader];
        }
        
        // fetch comments into array
        NSDictionary *comments = items[@"comments"];
        
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
        
        _tableView.scrollEnabled = YES;
        
        [_tableView reloadData];
    }];
}

#pragma mark - Rotation

- (void)setupOrientationNotifications {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

- (void)removeOrientationNotifications {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WZWebViewControllerSwipeRight object:nil];
}

- (void)didRotate:(id)sender {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    BOOL webViewVisible = _segmentedControl.selectedSegmentIndex == 1;
    
    _navigationView.hidden = webViewVisible && isLandscape;

    if (webViewVisible && isLandscape) {
        _webViewTopSpacing.constant = 0;
    } else {
        _webViewTopSpacing.constant = kNavigationBarHeight;
    }
}

- (void)showDefaultView {
    NSString *defaultView = [[NSUserDefaults standardUserDefaults] valueForKey:kSettingsDefaultReadingView];
    if ([defaultView isEqualToString:kSettingsDefaultReadingViewComments]) {
        _segmentedControl.selectedSegmentIndex = 0;
        [self segmentDidChange:_segmentedControl];
    } else if ([defaultView isEqualToString:kSettingsDefaultReadingViewLink]) {
        _segmentedControl.selectedSegmentIndex = 1;
        [self segmentDidChange:_segmentedControl];
    }
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
    if ([_post.type isEqualToString:@"ask"] && ![_post.type isEqualToString:@"job"]) { // hide if post is ASK HN
        _segmentedControl.hidden = YES;
    }

    NSDictionary *textAttributes =  @{
                                      UITextAttributeFont: [UIFont fontWithName:kTitleFontName size:13],
                                      UITextAttributeTextColor: [UIColor colorWithWhite:0.1 alpha:1],
                                      UITextAttributeTextShadowColor: [UIColor clearColor]
                                    };
    
    [_segmentedControl setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    
    [_segmentedControl addTarget:self action:@selector(segmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupTableView {
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self layoutTableViewHeader];
    [self layoutTableViewBackgrounds];
    
    _tableView.scrollEnabled = NO; // disable scrolling until comments loaded
}

- (void)setupWebView {
    _webViewController = [[WZWebViewController alloc] init];
    _webViewController.navigationBarHidden = YES;
    _webViewController.enabledGestures = YES;
    [_webViewController didMoveToParentViewController:self];
    
    _webView = _webViewController.view;
    _webView.hidden = YES;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addChildViewController:_webViewController];
    [self.view insertSubview:_webView belowSubview:_navigationView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewSwipeRight:) name:WZWebViewControllerSwipeRight object:nil];
    
    NSDictionary *viewDictionary = @{ @"webView": _webView };
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[webView(<=504)]"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:viewDictionary][0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"[webView(>=320)]"
                                                                                       options:0
                                                                                       metrics:nil
                                                                                         views:viewDictionary][0];

    _webViewTopSpacing = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-44-[webView]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewDictionary][0];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[webView]|"
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:viewDictionary][0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"|[webView]"
                                                                                    options:0
                                                                                 metrics:nil
                                                                                   views:viewDictionary][0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"[webView]|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:viewDictionary][0];
    [self.view addConstraint:heightConstraint];
    [self.view addConstraint:widthConstraint];
    [self.view addConstraint:_webViewTopSpacing];
    [self.view addConstraint:bottomConstraint];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:rightConstraint];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsPreloadLink]) {
        [_webViewController loadURL:[NSURL URLWithString:_post.url]];
    }
}


- (void)layoutTableViewHeader {
    if ([_post.type isEqualToString:@"ask"]) {
        _headerDomainLabel.text = @"Ask Hacker News";
    } else if ([_post.type isEqualToString:@"job"]) {
        _headerDomainLabel.text = @"Jobs";
    } else {
        _headerDomainLabel.text = _post.domain;
    }
    _headerMetadata1Label.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)_post.points, _post.user];
    _headerMetadata2Label.text = [NSString stringWithFormat:@"%@ · %lu comments", _post.timeAgo, (unsigned long)_post.commentsCount];
    _headerTitleLabel.text = _post.title;
    
    // calculate heights
    CGSize titleLabelSize = [_post.title sizeWithFont:[UIFont fontWithName:kTitleFontName size:kTitleFontSize]
                                    constrainedToSize:CGSizeMake(300, CGFLOAT_MAX)
                                        lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat titleHeight = titleLabelSize.height;
    
    CGFloat contentHeight = 0; // total height
    // set header details container frame to match contents height
    CGRect headerDetailsContainerViewFrame = _headerDetailsContainerView.frame;
    contentHeight = kHeaderTitleTopMargin + titleHeight + kHeaderTitleBottomMargin; // add details
    headerDetailsContainerViewFrame.size.height = contentHeight;
    
    CGFloat headerTextViewHeight = 0;
    
    // set the post content (AskHN)
    CGFloat headerTextViewBottomSpacingConstant = 0;
    if (_post.content) {
        headerTextViewBottomSpacingConstant = kHeaderTextBottomMargin;
        _headerTextView.hidden = NO;
        _headerTextView.delegate = self;
        _headerTextView.attributedText = _post.attributedContent;
        headerTextViewHeight = [_post contentHeightForWidth:kHeaderTextWidth] + kHeaderTextBottomMargin;
        contentHeight += headerTextViewHeight;
    }
    
    // set header view frame to match
    CGRect headerViewFrame = _headerView.frame;
    headerViewFrame.size.height = contentHeight;
    _headerView.frame = headerViewFrame;
    
    // set heights to views
    _headerDetailsContainerView.frame = headerDetailsContainerViewFrame;
    _headerTextViewTopConstraint.constant = headerDetailsContainerViewFrame.size.height;
    _headerTextViewBottomSpacing.constant = headerTextViewBottomSpacingConstant;
    _headerDetailViewBottomSpacing.constant = headerTextViewHeight;
    
    // update related views
    _activityIndicatorViewTopSpacing.constant = kNavigationBarHeight + headerDetailsContainerViewFrame.size.height;
    
    // err, fixes some kinda bug
    _tableView.tableHeaderView = _tableView.tableHeaderView;
}

- (void)layoutTableViewBackgrounds {
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, -480, 320, 480)];
    topView.backgroundColor = [UIColor whiteColor];
    [_tableView addSubview:topView];
}

#pragma mark - UISegmentDelegate

- (void)segmentDidChange:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    WZNavigationController *navigationController = (WZNavigationController *)self.navigationController;
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0: {
            _tableView.hidden = NO;
            _webView.hidden = YES;
            _webViewController.webView.scrollView.scrollsToTop = NO;
            _tableView.scrollsToTop = YES;
            navigationController.allowsRotation = NO;
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
            
            navigationController.allowsRotation = YES;
        }
        break;
    }
    
    for (int i = 0; i < segmentedControl.subviews.count; i++) {
        id segment = segmentedControl.subviews[i];
        if ([segment isSelected]) {
            [segment setTintColor:[UIColor colorWithWhite:0.82 alpha:1]];
        } else {
            [segment setTintColor:[UIColor colorWithWhite:0.95 alpha:1]];
        }
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

#pragma mark - WZCommentURLTappedDelegate & HeaderTextView link delegate

- (void)tappedLink:(NSURL *)url {
    if ([[url absoluteString] hasPrefix:@"http://www.youtube.com/v/"] ||
        [[url absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
        [[url absoluteString] hasPrefix:@"http://phobos.apple.com/"] ||
        [[url absoluteString] hasPrefix:@"https://www.youtube.com/v/"] ||
        [[url absoluteString] hasPrefix:@"https://itunes.apple.com/"] ||
        [[url absoluteString] hasPrefix:@"https://phobos.apple.com/"] ||
        [[url scheme] isEqual:@"mailto"] ||
        [[url scheme] isEqual:@"sms"]) {
        [[UIApplication sharedApplication] openURL:url];
        return;
    }
    
    WZWebViewController *webViewController = [[WZWebViewController alloc] initWithURL:url];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewPopupClosed) name:WZWebViewControllerDismissed object:nil];
    [self presentViewController:webViewController animated:YES completion:nil];
    
    _tableView.scrollsToTop = NO;
    webViewController.webView.scrollView.scrollsToTop = YES;
}

- (void)webViewPopupClosed {
    _tableView.scrollsToTop = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WZWebViewControllerDismissed object:nil];
}

- (BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo {
    [self tappedLink:linkInfo.extendedURL];
    return NO;
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
        
        for (NSUInteger i = currentRow; i < _comments.count; i++) {
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

- (IBAction)headerViewTapped:(id)sender {
    if (![_post.type isEqualToString:@"ask"] && ![_post.type isEqualToString:@"job"]) {
        [_segmentedControl setSelectedSegmentIndex:1];
        [self segmentDidChange:_segmentedControl];
    }
}

- (void)navigateBack {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        _isNavigatingBack = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)swipedBack:(id)sender {
    [self navigateBack];
}

- (IBAction)backButtonTapped:(id)sender {
    [self navigateBack];
}

- (void)webViewSwipeRight:(id)sender {
    [self navigateBack];
}

@end
