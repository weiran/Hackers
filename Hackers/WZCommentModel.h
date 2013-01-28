//
//  WZCommentModel.h
//  Hackers
//
//  Created by Weiran Zhang on 09/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZCommentModel : NSObject

@property (nonatomic, strong) NSString* content;
@property (nonatomic, strong) NSAttributedString *attributedContent;
@property (nonatomic, strong) NSNumber* id;
@property (nonatomic, strong) NSNumber* level;
@property (nonatomic, strong) NSString* timeAgo;
@property (nonatomic, strong) NSString* user;
@property (nonatomic, strong) NSArray* comments;
@property (nonatomic, strong) NSNumber *cellHeight;
@property (nonatomic) BOOL expanded;

- (void)updateAttributes:(NSDictionary *)attributes;
- (CGSize)sizeToFitWidth:(CGFloat)width;
- (NSUInteger)indentPoints;

@end
