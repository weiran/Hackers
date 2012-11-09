//
//  WZCommentsViewController.m
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentsViewController.h"
#import "WZHackersData.h"
#import "WZComment.h"

@interface WZCommentsViewController () {
    NSFetchedResultsController *_fetchedResultsController;
    NSArray *_comments;
}

@end

@implementation WZCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)fetchComments {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WZComment.entityName];
    
    
    [WZHackersData.shared fetchCommentsForPost:_postID completion:^(NSError *) {
        
    }];
}
@end
