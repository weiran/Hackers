//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <QuartzCore/QuartzCore.h>
#import "JSSlidingViewController.h"

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
@property (weak, nonatomic) UIView *webView;
@property (strong, nonatomic) WZWebViewController *webViewController;
@property (strong, nonatomic) UIPopoverController *activityPopoverController;

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
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupOrientationNotifications];
    [self setupActivityIndicatorView];
    [self setupTableView];
    [self setupSegmentedController];
    [self setupWebView];
    [self fetchComments];
    [self showDefaultView];
    
    if (IS_IPAD()) {
        self.backButton.hidden = YES;
    }
    
    _webViewController.webView.scrollView.scrollsToTop = NO;
    _tableView.scrollsToTop = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // set selected segement colours
    // uses GCD as it wont work if run immediately
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self segmentDidChange:_segmentedControl];
    });
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[[WZDefaults appDelegate] phoneViewController] setLocked:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self segmentDidChange:_segmentedControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_isNavigatingBack) {
        [self removeOrientationNotifications];
        _isNavigatingBack = NO;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [[[WZDefaults appDelegate] phoneViewController] setLocked:NO];
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
//    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
//    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
//    BOOL webViewVisible = _segmentedControl.selectedSegmentIndex == 1;
}

- (void)showDefaultView {
    if (![self postIsAskOrJob]) {
        NSString *defaultView = [[NSUserDefaults standardUserDefaults] valueForKey:kSettingsDefaultReadingView];
        if ([defaultView isEqualToString:kSettingsDefaultReadingViewComments]) {
            _segmentedControl.selectedSegmentIndex = 0;
            [self segmentDidChange:_segmentedControl];
        } else if ([defaultView isEqualToString:kSettingsDefaultReadingViewLink]) {
            _segmentedControl.selectedSegmentIndex = 1;
            [self segmentDidChange:_segmentedControl];
        }
    }
}

#pragma mark - Setup Views

- (void)setupActivityIndicatorView {
    [self.view bringSubviewToFront:_activityIndicatorView];
}

- (bool)postIsAskOrJob {
    return [_post.type isEqualToString:@"ask"] || [_post.type isEqualToString:@"job"];
}

- (void)setupSegmentedController {
    if ([self postIsAskOrJob]) { // hide if post is ASK HN
        _segmentedControl.hidden = YES;
    }

    NSDictionary *textAttributes =  @{
                                      UITextAttributeFont: [UIFont fontWithName:kTitleFontName size:13],
                                      UITextAttributeTextColor: [WZTheme titleTextColor],
                                      UITextAttributeTextShadowColor: [UIColor clearColor]
                                    };
    _segmentedControl.tintColor = [UIColor blackColor];
    [_segmentedControl setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    
    [_segmentedControl addTarget:self action:@selector(segmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupTableView {
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [WZTheme backgroundColor];
    _tableView.separatorColor = [WZTheme separatorColor];
    _activityIndicatorView.backgroundColor = [WZTheme backgroundColor];
    
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
    [self.view addSubview:_webView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewSwipeRight:) name:WZWebViewControllerSwipeRight object:nil];
    
    NSDictionary *viewDictionary = @{ @"webView": _webView };
    
    NSInteger width = IS_IPAD() ? 480 : 320;
    NSInteger height = IS_IPAD() ? 1000 : 504;
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[webView(<=%d)]", height]
                                                                                     options:0
                                                                                     metrics:nil
                                                                                       views:viewDictionary][0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"[webView(>=%d)]", width]
                                                                                       options:0
                                                                                       metrics:nil
                                                                                         views:viewDictionary][0];

    _webViewTopSpacing = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]"
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
    
    if (![self postIsAskOrJob]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kSettingsPreloadLink]) {
            [_webViewController loadURL:[NSURL URLWithString:_post.url]];
        }
    }
}


- (void)layoutTableViewHeader {
    // theme
    _headerTitleLabel.textColor = [WZTheme titleTextColor];
    _headerDomainLabel.textColor = [WZTheme subtitleTextColor];
    _headerMetadata1Label.textColor = [WZTheme detailTextColor];
    _headerMetadata2Label.textColor = [WZTheme detailTextColor];
    _headerView.backgroundColor = [WZTheme navigationColor];
    _headerDetailsContainerView.backgroundColor = [WZTheme navigationColor];
    
    _headerTextView.textColor = [WZTheme mainTextColor];
    _headerTextView.linkColor = [WZTheme subtitleTextColor];
    
    _headerMetadata1Label.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)_post.points, _post.user];
    _headerMetadata2Label.text = [NSString stringWithFormat:@"%@ · %lu comments", _post.timeAgo, (unsigned long)_post.commentsCount];
    _headerTitleLabel.text = _post.title;
    
    if ([_post.type isEqualToString:@"ask"]) {
        _headerDomainLabel.text = @"Ask Hacker News";
    } else if ([_post.type isEqualToString:@"job"]) {
        _headerDomainLabel.text = @"Jobs";
        _headerMetadata1Label.text = @"";
    } else {
        _headerDomainLabel.text = _post.domain;
    }
    
    // calculate heights
    CGFloat labelWidth = IS_IPAD() ? 460 : 300;
    CGSize titleLabelSize = [_post.title sizeWithFont:[UIFont fontWithName:kTitleFontName size:kTitleFontSize]
                                    constrainedToSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                        lineBreakMode:NSLineBreakByWordWrapping];
    CGFloat titleHeight = titleLabelSize.height;
    
    CGFloat contentHeight = 0; // total height
    // set header details container frame to match contents height
    CGRect headerDetailsContainerViewFrame = _headerDetailsContainerView.frame;
    NSInteger cellPadding = IS_IPAD() ? 72 : 53;
    contentHeight = titleHeight + cellPadding; // add details
    headerDetailsContainerViewFrame.size.height = contentHeight;
    
    CGFloat headerTextViewHeight = 0;
    
    // set the post content (AskHN or Job)
    CGFloat headerTextViewBottomSpacingConstant = 0;
    if (_post.content) {
        NSInteger bottomMargin = IS_IPAD() ? 20 : kHeaderTextBottomMargin;
        headerTextViewBottomSpacingConstant = bottomMargin;
        _headerTextView.hidden = NO;
        _headerTextView.delegate = self;
        _headerTextView.attributedText = _post.attributedContent;
        headerTextViewHeight = [_post contentHeightForWidth:labelWidth] + bottomMargin;
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
    topView.backgroundColor = [WZTheme navigationColor];
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
            [segment setTintColor:[WZTheme segmentSelectedBackgroundColor]];
        } else {
            [segment setTintColor:[WZTheme segmentBackgroundColor]];
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
    if (IS_IPAD()) {
        self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        [self.activityPopoverController presentPopoverFromRect:CGRectMake(self.shareButton.frame.origin.x, self.shareButton.frame.origin.y, 0, 0)
                                                        inView:self.view
                                      permittedArrowDirections:UIPopoverArrowDirectionUp
                                                      animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

- (IBAction)headerViewTapped:(id)sender {
    if (![self postIsAskOrJob]) {
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
