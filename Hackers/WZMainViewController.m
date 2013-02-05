    //
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <TSMiniWebBrowser.h>
#import <QuartzCore/QuartzCore.h>


#import "WZMainViewController.h"
#import "WZCommentsViewController.h"
#import "WZHackersData.h"
#import "WZPost.h"
#import "WZRead.h"
#import "WZPostCell.h"
#import "WZPostModel.h"

@interface WZMainViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_news;
    NSMutableArray *_readNews;
    UIRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
    BOOL _navBarInScrolledState;
    BOOL _navBarInDefaultState;
}
@end

@implementation WZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _readNews = [NSMutableArray array];
    
    [self setupPullToRefresh];
    [self setupTitle];
    [self loadData];
    
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.2];
}

- (void)navigationBarTapped:(id)sender {
    NSLog(@"Nav bar tapped");
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![[touch.view class] isSubclassOfClass:[UIControl class]];
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
    _refreshControl.tintColor = [UIColor colorWithWhite:0.4 alpha:1];
    [_refreshControl addTarget:self action:@selector(sendFetchRequest:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = _refreshControl;
    
    CGRect frame = self.tableView.bounds;
    frame.origin.y = -frame.size.height;
    UIView *backgroundView = [[UIView alloc] initWithFrame:frame];
    backgroundView.backgroundColor = backgroundColor;
    
    [self.tableView insertSubview:backgroundView atIndex:0];
}

- (void)setupTitle {
    if ([self newsType] == WZNewsTypeTop) {
        self.title = @"Hacker News";
    } else {
        self.title = @"Newest";
    }
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
    
    NSMutableArray *postArray = [NSMutableArray array];
    
    for (WZPost *post in _fetchedResultsController.fetchedObjects) {
        WZPostModel *postModel = [[WZPostModel alloc] initWithPost:post];
        [postArray addObject:postModel];
    }
    
    _news = [NSArray arrayWithArray:postArray];
    
    if (error) {
        NSLog(@"News fetch failed: %@", error.localizedDescription);
    }
}

- (void)updateNavigationBarBackground {
    _navBarInDefaultState = NO;
    [self scrollViewDidScroll:self.tableView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    
    if (offset.y > 0 && !_navBarInScrolledState) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-bg-highlighted.png"]
                                                      forBarMetrics:UIBarMetricsDefault];
        _navBarInScrolledState = YES;
        _navBarInDefaultState = NO;

    } else if (offset.y <= 0 && !_navBarInDefaultState) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-bg.png"]
                                                      forBarMetrics:UIBarMetricsDefault];
        _navBarInScrolledState = NO;
        _navBarInDefaultState = YES;
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
    WZPostModel *post = _news[indexPath.row];
    WZPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.domainLabel.text = post.domain;
    cell.detailLabel.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)post.points, post.user];
    cell.moreDetailLabel.text = [NSString stringWithFormat:@"%@ · %lu comments", post.timeAgo, (unsigned long)post.commentsCount];
    cell.rankLabel.text = [NSString stringWithFormat:@"%lu.", (unsigned long)post.rank];
    cell.titleLabel.text = post.title;
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self == %lu", post.id];
    NSArray *filteredReadNews = [_readNews filteredArrayUsingPredicate:filterPredicate];
    
    if (filteredReadNews.count > 0) {
        cell.titleLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
    } else {
        cell.titleLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPostModel *post = _news[indexPath.row];
    [_readNews addObject:[NSNumber numberWithInteger:post.id]];
    [WZHackersData.shared addRead:[NSNumber numberWithInteger:post.id]];
    WZPostCell *cell = (WZPostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.titleLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPostModel *post = _news[indexPath.row];
    
    if (!post.cellHeight) {
        CGSize size = [post.title sizeWithFont:[UIFont fontWithName:@"Futura" size:15]
                             constrainedToSize:CGSizeMake(275, CGFLOAT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        CGFloat height = MAX(size.height, 21);
        post.cellHeight = 54 + height;
    }
    
    return post.cellHeight;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCommentsSegue"]) {
        WZCommentsViewController *commentsViewController = segue.destinationViewController;
        
        WZPostModel *post = _news[[self.tableView indexPathForCell:sender].row];
        commentsViewController.post = post;
    }
}
@end
