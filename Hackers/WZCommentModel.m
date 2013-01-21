//
//  WZCommentModel.m
//  Hackers
//
//  Created by Weiran Zhang on 09/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "WZCommentModel.h"
#import "NSDictionary+ObjectForKeyOrNil.h"

#import "DTAttributedLabel.h"
#import "DTHTMLAttributedStringBuilder.h"
#import "DTCoreTextConstants.h"

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
            
            if ([comment.content hasPrefix:@"<p>"]) {
                comment.content = [comment.content substringFromIndex:3];
            }
            
            [newComments addObject:comment];
        }
        _comments = newComments;
    }
}

- (NSAttributedString *)attributedStringForHTML:(NSString *)html {
    NSDictionary *stringBuilderOptions = @{
        DTDefaultFontFamily: @"Helvetica Neue",
        NSTextSizeMultiplierDocumentOption: @(1.15)
    };
    
    DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc]
                                              initWithHTML:[html dataUsingEncoding:NSUTF8StringEncoding]
                                              options:stringBuilderOptions
                                              documentAttributes:nil];
    return [builder generatedAttributedString];
}

- (CGSize)sizeToFitWidth:(CGFloat)width {
    DTAttributedLabel *label = [[DTAttributedLabel alloc] init];
    [label setAttributedString:self.attributedContent];
    return [label suggestedFrameSizeToFitEntireStringConstraintedToWidth:width];
}

@end
