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
            [newComments addObject:comment];
        }
        _comments = newComments;
    }
}

- (NSAttributedString *)attributedStringForHTML:(NSString *)html {
    // first parse any unnecessary html paragraphs out
    if ([html hasSuffix:@"<p>"]) {
        html = [html substringToIndex:html.length - 3];
    }
    
    DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc]
                                              initWithHTML:[html dataUsingEncoding:NSUTF8StringEncoding]
                                              options:nil
                                              documentAttributes:nil];
    NSMutableAttributedString *attributedString = [[builder generatedAttributedString] mutableCopy];
    
    OHParagraphStyle *paragraphStyle = [OHParagraphStyle defaultParagraphStyle];
    paragraphStyle.lineBreakMode = kCTLineBreakByWordWrapping;
    paragraphStyle.lineSpacing = 3.f;
    paragraphStyle.paragraphSpacing = 12.f;
    attributedString.paragraphStyle = paragraphStyle;
    [attributedString setFont:[UIFont fontWithName:@"Avenir" size:14]];
    //[attributedString setFont:[UIFont systemFontOfSize:14]];
    
    return attributedString;
}

- (CGSize)sizeToFitWidth:(CGFloat)width {
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_attributedContent));
    CGSize sz = CGSizeMake(0.f, 0.f);
    CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
    
    if (framesetter) {
        CFRange fitCFRange = CFRangeMake(0,0);
        sz = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, maxSize, &fitCFRange);
        CFRelease(framesetter);
    }
    
    return sz;
}

@end
