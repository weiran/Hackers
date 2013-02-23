//
//  WZPostModel.h
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WZPost;

@interface WZPostModel : NSObject

- (id)initWithPost:(WZPost *)post;

@property (nonatomic) NSUInteger *commentsCount;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic) NSUInteger *id;
@property (nonatomic) NSUInteger *points;
@property (nonatomic) NSUInteger *postType;
@property (nonatomic) NSUInteger *rank;
@property (nonatomic, strong) NSString *timeAgo;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *user;
@property (nonatomic) BOOL isRead;
@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGFloat labelHeight;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSAttributedString *attributedContent;

- (CGFloat)contentHeightForWidth:(CGFloat)width;

@end
