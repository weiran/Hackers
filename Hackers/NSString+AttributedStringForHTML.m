//
//  NSString+AttributedStringForHTML.m
//  Hackers
//
//  Created by Weiran Zhang on 23/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "NSString+AttributedStringForHTML.h"

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <OHAttributedLabel/OHASBasicHTMLParser.h>
#import "DTHTMLAttributedStringBuilder.h"
#import "DTCoreTextConstants.h"

@implementation NSString (AttributedStringForHTML)

- (NSAttributedString *)attributedStringFromHTML {
    NSString *html = self;
    
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
    [attributedString setFont:[UIFont fontWithName:kBodyFontName size:kBodyFontSize]];
    
    return attributedString;
}

@end
