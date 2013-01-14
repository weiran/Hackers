//
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <TSMiniWebBrowser.h>
#import <SWRevealViewController/SWRevealViewController.h>

#import "WZMainViewController.h"
#import "WZCommentsViewController.h"
#import "WZMenuViewController.h"
#import "WZHackersData.h"
#import "WZPost.h"
#import "WZRead.h"
#import "WZPostCell.h"

@interface WZMainViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_news;
    NSMutableArray *_readNews;
    UIRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
}
@end

@implementation WZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _readNews = [NSMutableArray array];
    
    [self setupPullToRefresh];
    [self setupGestureRecognizer];
    [self setupBarButtons];
    [self setupTitle];

    [self loadData];
    
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.2];
}

- (void)sendFetchRequest:(UIRefreshControl *)sender {
    [sender beginRefreshing];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [WZHackersData.shared fetchNewsOfType:[self newsType] completion:^(NSError *error) {
        [self performSelector:@selector(endRefreshing:) withObject:error afterDelay:0.5];
    }];
}

- (void)endRefreshing:(NSError *)error {
    if (!error) {
        [self loadData];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshControl endRefreshing];
    });
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)setupPullToRefresh {
    UIColor *backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:1];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = backgroundColor;
    [_refreshControl addTarget:self action:@selector(sendFetchRequest:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = _refreshControl;
    
    CGRect frame = self.tableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView *backgroundView = [[UIView alloc] initWithFrame:frame];
    backgroundView.backgroundColor = backgroundColor;
    
    [self.tableView insertSubview:backgroundView atIndex:0];
}

- (void)setupGestureRecognizer {
//    WZMenuViewController *menuViewController = (WZMenuViewController *)self.parentViewController.parentViewController;
//    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:menuViewController action:@selector(panItem:)];
//    [panGesture setMaximumNumberOfTouches:2];
//    [panGesture setDelegate:menuViewController];
//    [self.view addGestureRecognizer:panGesture];
//    [self.navigationController.view addGestureRecognizer:panGesture];
    
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)setupTitle {
    if ([self newsType] == WZNewsTypeTop) {
        self.title = @"Top News";
    } else {
        self.title = @"Newest";
    }
}

- (void)setupBarButtons {
//    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuicon.png"]
//                                                                   style:UIBarButtonItemStyleBordered
//                                                                  target:self.revealViewController
//                                                                  action:@selector(revealToggle:)];
//    self.navigationItem.leftBarButtonItem = menuButton;
    _menuBarButtonItem.target = self.revealViewController;
    _menuBarButtonItem.action = @selector(revealToggle:);
}

- (WZNewsType)newsType {
    if (!_newsType) {
        _newsType = WZNewsTypeTop;
    }
    
    return _newsType;
}

#pragma mark - Data access

- (void)loadData {
    [self loadNews];
    [self loadRead];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.tableView setNeedsDisplay];
    });
}

- (void)loadNews {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WZPost.entityName];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"rank" ascending:YES];
    request.sortDescriptors = @[sortDescriptor];
    request.predicate = [NSPredicate predicateWithFormat:@"postType == %d", [self newsType]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                    managedObjectContext:[WZHackersData.shared context]
                                                                      sectionNameKeyPath:nil cacheName:nil];
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    _news = _fetchedResultsController.fetchedObjects;
    
    if (!_news.count > 0) {
        self.tableView.hidden = YES;
        _activityIndicator.hidden = NO;
    } else {
        self.tableView.hidden = NO;
        _activityIndicator.hidden = YES;
    }
    
    if (error) {
        NSLog(@"News fetch failed: %@", error.localizedDescription);
    }
    
}

- (void)loadRead {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WZRead.entityName];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:NO];
    request.sortDescriptors = @[sortDescriptor];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                    managedObjectContext:[WZHackersData.shared context]
                                                                      sectionNameKeyPath:nil cacheName:nil];
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Read news fetch failed: %@", error.localizedDescription);
    }
    
    NSArray *readNews = _fetchedResultsController.fetchedObjects;
    
    for (WZRead *read in readNews) {
        [_readNews addObject:read.id];
    }

}

#pragma mark - UITableViewController methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_news) {
        return 0;
    } else {
        return _news.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const cellIdentifier = @"PostCell";
    WZPost *post = _news[indexPath.row];
    WZPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.domainLabel.text = post.domain;
    cell.detailLabel.text = [NSString stringWithFormat:@"%@ points by %@", post.points, post.user];
    cell.moreDetailLabel.text = [NSString stringWithFormat:@"%@ · %@ comments", post.timeAgo, post.commentsCount];
    cell.rankLabel.text = [NSString stringWithFormat:@"%@.", post.rank];
    cell.titleLabel.text = post.title;
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self == %@", post.id];
    NSArray *filteredReadNews = [_readNews filteredArrayUsingPredicate:filterPredicate];
    
    if (filteredReadNews.count > 0) {
        cell.titleLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.titleLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPost *post = _news[indexPath.row];
    
    [_readNews addObject:post.id];
    [WZHackersData.shared addRead:post.id];
    
    WZPostCell *cell = (WZPostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.titleLabel.textColor = [UIColor lightGrayColor];
    
//    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:post.url];
//    webViewController.itemTitle = post.title;
//    [self.navigationController pushViewController:webViewController animated:YES];
    
    TSMiniWebBrowser *webBrowser = [[TSMiniWebBrowser alloc] initWithUrl:[NSURL URLWithString:post.url]];
    [self.navigationController pushViewController:webBrowser animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPost *post = _news[indexPath.row];
    
    if (!post.cellHeight) {
        CGSize size = [post.title sizeWithFont:[UIFont boldSystemFontOfSize:15.0f]
                             constrainedToSize:CGSizeMake(252, CGFLOAT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = MAX(size.height, 21);
        post.cellHeight = 58 + height;
    }
    
    return post.cellHeight;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCommentsSegue"]) {
        WZCommentsViewController *commentsViewController = segue.destinationViewController;
        
        WZPost *post = _news[[self.tableView indexPathForCell:sender].row];
        commentsViewController.post = post;
    }
}
@end
