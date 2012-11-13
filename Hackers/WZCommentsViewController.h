//
//  WZCommentsViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RTLabel/RTLabel.h>
#import "WZCommentCell.h"

@class WZPost;

@interface WZCommentsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, RTLabelDelegate, WZCommentShowRepliesDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) WZPost *post;
@property (strong, nonatomic) NSMutableArray *comments;

@end
