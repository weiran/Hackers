//
//  WZCommentCell.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WZCommentModel, RTLabel;

@protocol WZCommentShowRepliesDelegate <NSObject>
- (void)selectedComment:(WZCommentModel *)comment atIndexPath:(NSIndexPath *)indexPath;
@end

@interface WZCommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet RTLabel *commentLabel;

- (IBAction)showReplies:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *showRepliesButton;

@property (copy, nonatomic) WZCommentModel *comment;

@property (weak, nonatomic) id <WZCommentShowRepliesDelegate> delegate;


//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *repliesButtonLayoutConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyLayoutConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userLayoutConstraint;

@end
