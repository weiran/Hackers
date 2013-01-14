//
//  WZCommentCell.h
//  Hackers
//
//  Created by Weiran Zhang on 08/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RTLabel, CLinkingCoreTextLabel;

@protocol WZCommentShowRepliesDelegate <NSObject>
- (void)selectedCommentAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol WZCommentURLRequested <NSObject>
- (void)tappedLink:(NSURL *)url;
@end

@interface WZCommentCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet CLinkingCoreTextLabel *commentLabel;

- (IBAction)showReplies:(id)sender;
- (void)setHTML:(NSString *)html;

@property (weak, nonatomic) IBOutlet UIButton *showRepliesButton;

@property (nonatomic) NSUInteger contentIndent;
@property (nonatomic) BOOL expanded;
@property (nonatomic) NSUInteger repliesCount;

@property (weak, nonatomic) id <WZCommentShowRepliesDelegate> delegate;
@property (weak, nonatomic) id <WZCommentURLRequested> linkDelegate;

@end