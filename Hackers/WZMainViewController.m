    //
//  WZMainViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "JSSlidingViewController.h"
#import "UIViewController+CLCascade.h"
#import "CLCascadeNavigationController.h"

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

@interface WZMainViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_news;
    NSArray *_newNews;
    NSArray *_askNews;
    NSInteger _topNewsPage;
    
    UIView *_tableViewBackgroundView;
    NSMutableArray *_readNews;
    UIRefreshControl *_refreshControl;
    UIPopoverController *_popoverController;
    BOOL _navBarInScrolledState;
    BOOL _navBarInDefaultState;
    NSIndexPath *_selectedIndexPath;
    WZNewsType _newsType;
}
- (IBAction)menuButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
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
    
    [_menuButton setImage:[UIImage themeImageNamed:@"menu-icon"] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tableView.backgroundColor = [WZTheme backgroundColor];
    [self setupPullToRefresh];
}

#pragma mark - Fetch

- (void)sendFetchRequest:(UIRefreshControl *)sender {
    [sender beginRefreshing];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 2, 2) animated:YES];
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
    UIColor *backgroundColor = [WZTheme backgroundColor];
    
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(sendFetchRequest:) forControlEvents:UIControlEventValueChanged];
        _refreshControl.tintColor = [UIColor colorWithWhite:0.4 alpha:1];
        self.refreshControl = _refreshControl;
    }
    _refreshControl.backgroundColor = backgroundColor;

    if (!_tableViewBackgroundView) {
        CGRect frame = self.tableView.bounds;
        frame.origin.y = -frame.size.height;
        _tableViewBackgroundView = [[UIView alloc] initWithFrame:frame];
    
        [self.tableView insertSubview:_tableViewBackgroundView atIndex:0];
    }
    _tableViewBackgroundView.backgroundColor = backgroundColor;
}


- (WZNewsType)newsType {
    if (!_newsType) {
        _newsType = WZNewsTypeTop;
    }
    
    return _newsType;
}

- (void)setNewsType:(WZNewsType)newsType {
    if (_newsType != newsType) {
        _newsType = newsType;
        [self reloadTableViewAnimated:YES];
        [self.tableView setContentOffset:CGPointZero animated:YES];
        [self performSelector:@selector(sendFetchRequest:) withObject:_refreshControl afterDelay:0.3];
        [self updateTitle];
    }
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
//    request.predicate = [NSPredicate predicateWithFormat:@"postType == %d", [self newsType]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                    managedObjectContext:[WZHackersData.shared context]
                                                                      sectionNameKeyPath:nil cacheName:nil];
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    NSMutableArray *topPostArray = [NSMutableArray array];
    NSMutableArray *newPostArray = [NSMutableArray array];
    NSMutableArray *askPostArray = [NSMutableArray array];
    
    for (WZPost *post in _fetchedResultsController.fetchedObjects) {
        WZPostModel *postModel = [[WZPostModel alloc] initWithPost:post];
        if (postModel.postType == 0) {
            [topPostArray addObject:postModel];
        } else if (postModel.postType == 1) {
            [newPostArray addObject:postModel];
        } else if (postModel.postType == 2) {
            [askPostArray addObject:postModel];
        }
    }
    
    _news = [NSArray arrayWithArray:topPostArray];
    _newNews = [NSArray arrayWithArray:newPostArray];
    _askNews = [NSArray arrayWithArray:askPostArray];
    
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
            self.title = @"Top";
            break;
            
        case WZNewsTypeNew:
            self.title = @"New";
            break;
            
        case WZNewsTypeAsk:
            self.title = @"Ask";
            break;
            
        default:
            break;
    }
}

- (void)reloadTableViewAnimated:(bool)animated {
    [UIView transitionWithView:self.tableView
                      duration:0.3f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [self.tableView reloadData];
                    } completion:nil];
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
        cell.contentView.backgroundColor = [WZTheme backgroundColor];
        [self sendFetchRequestWithPage:2];
        return cell;
    } else {
        // standard cell
        WZPostModel *post = [self activeNews][indexPath.row];
        WZPostCell *cell = [tableView dequeueReusableCellWithIdentifier:postCellIdentifier];

        cell.detailLabel.text = [NSString stringWithFormat:@"%lu points by %@", (unsigned long)post.points, post.user];
        cell.moreDetailLabel.text = [NSString stringWithFormat:@"%@ · %lu comments", post.timeAgo, (unsigned long)post.commentsCount];
        cell.titleLabel.text = post.title;
        if ([post.type isEqualToString:@"ask"]) {
            cell.domainLabel.text = @"Ask Hacker News";
        } else if ([post.type isEqualToString:@"job"]) {
            cell.domainLabel.text = @"Job";
            cell.detailLabel.text = @"";
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
    NSInteger cellPadding = IS_IPAD() ? 72 : 53;
    
    // if it's the loading cell
    if (_newsType == WZNewsTypeTop && indexPath.row == _news.count && _topNewsPage == 1) {
        return 74;
    }
    
    WZPostModel *post = [self activeNews][indexPath.row];
    
    if (!post.cellHeight) {
        CGFloat width = 275; //iphone width
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            width = self.view.frame.size.width;
        }
        
        CGSize size = [post.title sizeWithFont:[UIFont fontWithName:kTitleFontName size:kTitleFontSize]
                             constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        CGFloat height = size.height;
        CGFloat cellHeight = cellPadding + height;
        post.cellHeight = cellHeight;
    }
    
    return post.cellHeight;
}

#pragma mark - Segue

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"ShowCommentsSegue"]) {
        if (IS_IPAD()) {
            // prevent segue and do custom push
            UINavigationController *commentsNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"CommentsNavigationController"];
            WZCommentsViewController *commentsViewController = commentsNavController.viewControllers[0];
            commentsViewController.post = [self activeNews][[self.tableView indexPathForCell:sender].row];
            [self.cascadeNavigationController addViewController:commentsNavController sender:self animated:YES];
            return NO;
        }
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCommentsSegue"]) {
        WZCommentsViewController *commentsViewController = segue.destinationViewController;
        WZPostModel *post = [self activeNews][[self.tableView indexPathForCell:sender].row];
        commentsViewController.post = post;
    }
}

#pragma - mark Menu

- (IBAction)menuButtonPressed:(id)sender {
    if (!IS_IPAD()) {
        if ([[[WZDefaults appDelegate] phoneViewController] isOpen]) {
            [[[WZDefaults appDelegate] phoneViewController] closeSlider:YES completion:nil];
        } else {
            [[[WZDefaults appDelegate] phoneViewController] openSlider:YES completion:nil];
        }
    }
}

@end
