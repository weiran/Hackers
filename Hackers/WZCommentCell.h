//
//  WZCommentCell.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WZCommentModel, RTLabel;

@interface WZCommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet RTLabel *commentLabel;


@property (copy, nonatomic) WZCommentModel *comment;

@end
