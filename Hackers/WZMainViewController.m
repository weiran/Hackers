//
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <ODRefreshControl/ODRefreshControl.h>
#import <SVWebViewController/SVWebViewController.h>

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
    ODRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
}
@end

@implementation WZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _readNews = [NSMutableArray array];
    
    [self setupPullToRefresh];
    [self setupTableView];
    [self setupGestureRecognizer];
    [self setupBarButtons];
    [self setupTitle];

    [self loadData];
    
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.2];
}

- (void)sendFetchRequest:(ODRefreshControl *)sender {
    [sender beginRefreshing];
    [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [WZHackersData.shared fetchNewsOfType:[self newsType] completion:^(NSError *error) {
        [self performSelector:@selector(endRefreshing:) withObject:error afterDelay:0.5];
    }];
}

- (void)endRefreshing:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshControl endRefreshing];
    });
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (!error) {
        [self loadData];
    }
}

- (void)setupPullToRefresh {
    _refreshControl = [[ODRefreshControl alloc] initInScrollView:self.tableView];
    [_refreshControl addTarget:self action:@selector(sendFetchRequest:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupTableView {
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)setupGestureRecognizer {
    WZMenuViewController *menuViewController = (WZMenuViewController *)self.parentViewController.parentViewController;
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:menuViewController action:@selector(panItem:)];
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:menuViewController];
    [self.view addGestureRecognizer:panGesture];
    [self.navigationController.view addGestureRecognizer:panGesture];
}

- (void)setupTitle {
    if ([self newsType] == WZNewsTypeTop) {
        self.title = @"Top News";
    } else {
        self.title = @"Newest";
    }
}

- (void)setupBarButtons {
    WZMenuViewController *menuViewController = (WZMenuViewController *)self.parentViewController.parentViewController;
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuicon.png"]
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:menuViewController
                                                                  action:@selector(doSlideOut)];
    self.navigationItem.leftBarButtonItem = menuButton;
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
        _tableView.hidden = YES;
        _activityIndicator.hidden = NO;
    } else {
        _tableView.hidden = NO;
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
    
    WZPostCell *cell = (WZPostCell *)[_tableView cellForRowAtIndexPath:indexPath];
    cell.titleLabel.textColor = [UIColor lightGrayColor];
    
    SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:post.url];
    [self.navigationController pushViewController:webViewController animated:YES];
    [_tableView deselectRowAtIndexPath:indexPath animated:NO];
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
        
        WZPost *post = _news[[_tableView indexPathForCell:sender].row];
        commentsViewController.post = post;
    }
}

- (IBAction)showMenu:(id)sender {
}
@end
