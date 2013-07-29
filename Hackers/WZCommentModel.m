//
//  WZCommentModel.m
//  Hackers
//
//  Created by Weiran Zhang on 09/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <OHAttributedLabel/OHAttributedLabel.h>

#import "WZCommentModel.h"
#import "NSDictionary+ObjectForKeyOrNil.h"
#import "NSString+AttributedStringForHTML.h"

#define kCellWidth 320
#define kCellWidthiPad 480
#define kCellPadding IS_IPAD() ? 44 : 39
#define kReplyButtonHeightWithMargin 40
#define kDefaultTrailingMargin 10

@implementation WZCommentModel

- (void)updateAttributes:(NSDictionary *)attributes {
    self.content = [attributes objectForKeyOrNil:@"content"];
    self.id = [attributes objectForKeyOrNil:@"id"];
    self.level = [attributes objectForKeyOrNil:@"level"];
    self.timeAgo = [attributes objectForKeyOrNil:@"time_ago"];
    self.user = [attributes objectForKeyOrNil:@"user"];
    NSDictionary *comments = [attributes objectForKeyOrNil:@"comments"];
    self.attributedContent = [self attributedStringForHTML:self.content];
    
    if (comments) {
        NSMutableArray *newComments = [NSMutableArray array];
        for (NSDictionary *commentDictionary in comments) {
            WZCommentModel *comment = [[WZCommentModel alloc] init];
            [comment updateAttributes:commentDictionary];
            [newComments addObject:comment];
        }
        _comments = newComments;
    }
    
    self.cellHeight = [self heightForComment:self];
}

- (NSAttributedString *)attributedStringForHTML:(NSString *)html {
    return [html attributedStringFromHTML];
}

- (NSNumber *)heightForComment:(WZCommentModel *)comment constrainedToSize:(CGSize)size {
    int indentPoints = [self indentPointsForComment:comment];
    CGFloat width = size.width - indentPoints - kDefaultTrailingMargin;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(comment.attributedContent));
    CGSize calculatedSize = CGSizeMake(0.f, 0.f);
    CGSize maxSize = CGSizeMake(width, size.height);
    
    if (framesetter) {
        CFRange fitCFRange = CFRangeMake(0, 0);
        calculatedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, maxSize, &fitCFRange);
        CFRelease(framesetter);
    }
    
    int labelHeight = calculatedSize.height;
    
    CGFloat cellPadding = IS_IPAD() ? 48 : 39;
    
    CGFloat height = cellPadding + labelHeight; // 29 points to top, 10 points to bottom
    
    if (self.comments.count > 0) {
        height += kReplyButtonHeightWithMargin;
    }
    
    return @(height);

}

- (NSNumber *)heightForComment:(WZCommentModel *)comment {
    CGFloat cellWidth = IS_IPAD() ? kCellWidthiPad : kCellWidth;
    return [self heightForComment:comment constrainedToSize:CGSizeMake(cellWidth, CGFLOAT_MAX)];
}

- (CGSize)sizeToFitWidth:(CGFloat)width {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_attributedContent));
    CGSize calculatedSize = CGSizeMake(0.f, 0.f);
    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
    
    if (framesetter) {
        CFRange fitCFRange = CFRangeMake(0,0);
        calculatedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, maxSize, &fitCFRange);
        CFRelease(framesetter);
    }
    
    return calculatedSize;
}

#define kBaseIndent 10
#define kIndentPerLevel 15

- (NSUInteger)indentPointsForComment:(WZCommentModel *)comment {
    NSUInteger indentation = kBaseIndent + (kIndentPerLevel * comment.level.integerValue);
    return indentation;
}

- (NSUInteger)indentPoints {
    return [self indentPointsForComment:self];
}

@end
