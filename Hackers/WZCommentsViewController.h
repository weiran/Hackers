//
//  WZCommentsViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WZPostModel;

@interface WZCommentsViewController : UIViewController

@property (weak, nonatomic) WZPostModel *post;
@property (strong, nonatomic) NSMutableArray *comments;

@end
