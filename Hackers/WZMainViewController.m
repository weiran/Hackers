    //
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "REMenu.h"

#import "WZMainViewController.h"
#import "WZCommentsViewController.h"
#import "WZHackersData.h"
#import "WZPost.h"
#import "WZRead.h"
#import "WZPostCell.h"
#import "WZPostModel.h"

#define kTitleUnreadTextColorWithWhite 0
#define kTitleReadTextColorWithWhite 0.4
#define kCellTitleTopMargin 9
#define kCellTitleBottomMargin 44

@interface WZMainViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_news;
    NSArray *_newNews;
    NSMutableArray *_readNews;
    UIRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
    BOOL _navBarInScrolledState;
    BOOL _navBarInDefaultState;
    NSIndexPath *_selectedIndexPath;
    REMenu *_menu;
}
- (IBAction)menuButtonPressed:(id)sender;
@end

@implementation WZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _readNews = [NSMutableArray array];
    _newsType = WZNewsTypeTop;
    
    [self setupPullToRefresh];
    [self setupMenu];
    [self loadData];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.5];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performSelector:@selector(deselectCurrentRow) withObject:nil afterDelay:0.3];
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

- (void)setupMenu {
    REMenuItem *topNewsItem = [[REMenuItem alloc] initWithTitle:@"Top News"
                                                          image:nil
                                               highlightedImage:nil
                                                         action:^(REMenuItem *item) {
                                                             [self menuButtonTopPressed:item];
                                                         }];
    REMenuItem *newNewsItem = [[REMenuItem alloc] initWithTitle:@"New News"
                                                          image:nil
                                               highlightedImage:nil
                                                         action:^(REMenuItem *item) {
                                                             [self menuButtonNewPressed:item];
                                                         }];
    _menu = [[REMenu alloc] initWithItems:@[topNewsItem, newNewsItem]];
    _menu.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    _menu.cornerRadius = 0;
    _menu.shadowColor = [UIColor blackColor];
    _menu.shadowOffset = CGSizeMake(0, 0);
    _menu.shadowOpacity = 0.4;
    _menu.shadowRadius = 2;
    _menu.separatorColor = [UIColor colorWithWhite:0.87 alpha:1];
    _menu.highlightedSeparatorColor = [UIColor colorWithWhite:0.87 alpha:1];
    _menu.separatorHeight = 1;
    _menu.font = [UIFont fontWithName:kTitleFontName size:kTitleFontSize];
    _menu.textColor = [UIColor blackColor];
    _menu.highlighedTextColor = [UIColor blackColor];
    _menu.textShadowColor = [UIColor clearColor];
    _menu.highlighedTextShadowColor = [UIColor clearColor];
    _menu.borderWidth = 0;
    _menu.highligtedBackgroundColor = [UIColor colorWithWhite:0.87 alpha:1];
}

- (WZNewsType)newsType {
    if (!_newsType) {
        _newsType = WZNewsTypeTop;
    }
    
    return _newsType;
}

- (NSArray *)activeNews {
    if (_newsType == WZNewsTypeTop) {
        return _news;
    } else if (_newsType == WZNewsTypeNew) {
        return _newNews;
    } else {
        return nil;
    }
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
    
    if (_newsType == WZNewsTypeTop) {
        _news = [NSArray arrayWithArray:postArray];
    } else if (_newsType == WZNewsTypeNew) {
        _newNews = [NSArray arrayWithArray:postArray];
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

- (void)deselectCurrentRow {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:_selectedIndexPath animated:YES]; 
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![self activeNews]) {
        return 0;
    } else {
        return [self activeNews].count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const cellIdentifier = @"PostCell";
    
    WZPostModel *post = [self activeNews][indexPath.row];
    WZPostCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.detailLabel.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)post.points, post.user];
    cell.moreDetailLabel.text = [NSString stringWithFormat:@"%@ · %lu comments", post.timeAgo, (unsigned long)post.commentsCount];
    cell.rankLabel.text = [NSString stringWithFormat:@"%lu.", (unsigned long)post.rank];
    cell.titleLabel.text = post.title;
    if ([post.type isEqualToString:@"ask"]) {
        cell.domainLabel.text = @"Ask Hacker News";
    } else {
        cell.domainLabel.text = post.domain;
    }
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self == %lu", post.id];
    NSArray *filteredReadNews = [_readNews filteredArrayUsingPredicate:filterPredicate];
    
    if (filteredReadNews.count > 0) {
        cell.titleLabel.textColor = [UIColor colorWithWhite:kTitleReadTextColorWithWhite alpha:1];
    } else {
        cell.titleLabel.textColor = [UIColor colorWithWhite:kTitleUnreadTextColorWithWhite alpha:1];
    }
    
    if ([_selectedIndexPath isEqual:indexPath]) {
        [cell setSelected:YES];
    } else {
        [cell setSelected:NO];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPostModel *post = [self activeNews][indexPath.row];
    [_readNews addObject:[NSNumber numberWithInteger:post.id]];
    [WZHackersData.shared addRead:[NSNumber numberWithInteger:post.id]];
    WZPostCell *cell = (WZPostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.titleLabel.textColor = [UIColor colorWithWhite:kTitleReadTextColorWithWhite alpha:1];
    _selectedIndexPath = indexPath;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPostModel *post = [self activeNews][indexPath.row];
    
    if (!post.cellHeight) {
        CGSize size = [post.title sizeWithFont:[UIFont fontWithName:kTitleFontName size:kTitleFontSize]
                             constrainedToSize:CGSizeMake(275, CGFLOAT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        CGFloat height = size.height;
        post.cellHeight = kCellTitleTopMargin + height + kCellTitleBottomMargin;
    }
    
    return post.cellHeight;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCommentsSegue"]) {
        WZCommentsViewController *commentsViewController = segue.destinationViewController;
        WZPostModel *post = [self activeNews][[self.tableView indexPathForCell:sender].row];
        commentsViewController.post = post;
    }
}

#pragma - mark Menu

- (IBAction)menuButtonPressed:(id)sender {
    if ([_menu isOpen]) {
        [_menu close];
    } else {
        [_menu showFromNavigationController:self.navigationController];
    }
}

- (void)menuButtonTopPressed:(id)sender {
    self.newsType = WZNewsTypeTop;
    [self.tableView reloadData];
    
    if (![self activeNews].count > 0) {
        [self sendFetchRequest:_refreshControl];
    }
}

- (void)menuButtonNewPressed:(id)sender {
    self.newsType = WZNewsTypeNew;
    [self.tableView reloadData];
    
    if (![self activeNews].count > 0) {
        [self sendFetchRequest:_refreshControl];
    }
}

@end
