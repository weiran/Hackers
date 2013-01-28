//
//  WZCommentsViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WZCommentCell.h"

@class WZPost, TSMiniWebBrowser;

@interface WZCommentsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, WZCommentShowRepliesDelegate, WZCommentURLRequested, TSMiniWebBrowserDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) WZPost *post;
@property (strong, nonatomic) NSMutableArray *comments;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *headerTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerDomainLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata1Label;
@property (weak, nonatomic) IBOutlet UILabel *headerMetadata2Label;

@end
