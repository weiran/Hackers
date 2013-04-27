    //
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "REMenu.h"
#import "JSSlidingViewController.h"

#import "WZMainViewController.h"
#import "WZCommentsViewController.h"
#import "WZHackersData.h"
#import "WZPost.h"
#import "WZRead.h"
#import "WZPostCell.h"
#import "WZPostModel.h"
#import "WZNotify.h"

#define kTitleUnreadTextColorWithWhite 0
#define kTitleReadTextColorWithWhite 0.4
#define kCellTitleTopMargin 9
#define kCellTitleBottomMargin 44

@interface WZMainViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_news;
    NSArray *_newNews;
    NSArray *_askNews;
    NSInteger _topNewsPage;
    
    NSMutableArray *_readNews;
    UIRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
    BOOL _navBarInScrolledState;
    BOOL _navBarInDefaultState;
    NSIndexPath *_selectedIndexPath;
    WZNewsType _newsType;
}
- (IBAction)menuButtonPressed:(id)sender;
@end

@implementation WZMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _readNews = [NSMutableArray array];
    _newsType = WZNewsTypeTop;
    _topNewsPage = 1;
    
    [self setupPullToRefresh];
    [self loadData];
    [self updateTitle];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.5];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performSelector:@selector(deselectCurrentRow) withObject:nil afterDelay:0.3];
}

#pragma mark - Fetch

- (void)sendFetchRequest:(UIRefreshControl *)sender {
    [sender beginRefreshing];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
    [WZHackersData.shared fetchNewsOfType:[self newsType] page:1 completion:^(NSError *error) {
        _topNewsPage = 1;
        [self performSelector:@selector(endRefreshing:) withObject:error afterDelay:0.5];
    }];
}

- (void)sendFetchRequestWithPage:(NSInteger)page {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;    
    [WZHackersData.shared fetchNewsOfType:[self newsType] page:page completion:^(NSError *error) {
        if (!error) {
            _topNewsPage = page;
        }
        
        [self endRefreshing:error];
    }];
}

- (void)endRefreshing:(NSError *)error {
    if (!error) {
        [self loadData];
    } else {
        [WZNotify showMessage:@"Failed loading news" inView:self.navigationController.view duration:2];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshControl endRefreshing];
    });
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)setupPullToRefresh {
    UIColor *backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
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


- (WZNewsType)newsType {
    if (!_newsType) {
        _newsType = WZNewsTypeTop;
    }
    
    return _newsType;
}

- (void)setNewsType:(WZNewsType)newsType {
    _newsType = newsType;
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:YES];
    [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.5];
    [self updateTitle];
    
}

- (NSArray *)activeNews {
    if (_newsType == WZNewsTypeTop) {
        return _news;
    } else if (_newsType == WZNewsTypeNew) {
        return _newNews;
    } else if (_newsType == WZNewsTypeAsk) {
        return _askNews;
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
    } else if (_newsType == WZNewsTypeAsk) {
        _askNews = [NSArray arrayWithArray:postArray];
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

- (void)updateTitle {
    switch (_newsType) {
        case WZNewsTypeTop:
            self.title = @"Top Hacker News";
            break;
            
        case WZNewsTypeNew:
            self.title = @"New Hacker News";
            break;
            
        case WZNewsTypeAsk:
            self.title = @"Ask Hacker News";
            break;
            
        default:
            break;
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
        if (_newsType == WZNewsTypeTop) {
            // currently, only support page 2
            if (_topNewsPage > 1) {
                return _news.count;
            } else {
                return _news.count + 1;
            }
        } else {
            return [self activeNews].count;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const postCellIdentifier = @"PostCell";
    static NSString *const loadingCellIdentifier = @"LoadingCell";
    
    // if we're on the loading cell
    if (_newsType == WZNewsTypeTop && indexPath.row == _news.count && _topNewsPage == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
        [self sendFetchRequestWithPage:2];
        return cell;
    } else {    
        WZPostModel *post = [self activeNews][indexPath.row];
        WZPostCell *cell = [tableView dequeueReusableCellWithIdentifier:postCellIdentifier];
        cell.detailLabel.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)post.points, post.user];
        cell.moreDetailLabel.text = [NSString stringWithFormat:@"%@ · %lu comments", post.timeAgo, (unsigned long)post.commentsCount];
    //    cell.rankLabel.text = [NSString stringWithFormat:@"%lu.", (unsigned long)post.rank];
        cell.titleLabel.text = post.title;
        if ([post.type isEqualToString:@"ask"]) {
            cell.domainLabel.text = @"Ask Hacker News";
        } else if ([post.type isEqualToString:@"ask"]) {
            cell.domainLabel.text = @"Job";
        } else {
            cell.domainLabel.text = post.domain;
        }
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self == %lu", post.id];
        NSArray *filteredReadNews = [_readNews filteredArrayUsingPredicate:filterPredicate];
        
        if (filteredReadNews.count > 0) {
            cell.readBadgeImageView.hidden = YES;
        } else {
            cell.readBadgeImageView.hidden = NO;
        }
        
        if ([_selectedIndexPath isEqual:indexPath]) {
            [cell setSelected:YES];
        } else {
            [cell setSelected:NO];
        }
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WZPostModel *post = [self activeNews][indexPath.row];
    [_readNews addObject:[NSNumber numberWithInteger:post.id]];
    [WZHackersData.shared addRead:[NSNumber numberWithInteger:post.id]];
    WZPostCell *cell = (WZPostCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.readBadgeImageView.hidden = YES;
    _selectedIndexPath = indexPath;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // if it's the loading cell
    if (_newsType == WZNewsTypeTop && indexPath.row == _news.count && _topNewsPage == 1) {
        return 74;
    }
    
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
    if ([[[WZDefaults appDelegate] viewController] isOpen]) {
        [[[WZDefaults appDelegate] viewController] closeSlider:YES completion:nil];
    } else {
        [[[WZDefaults appDelegate] viewController] openSlider:YES completion:nil];
    }
}

@end
