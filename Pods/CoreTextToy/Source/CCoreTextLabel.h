//
//  CCoreTextLabel.h
//  TouchCode
//
//  Created by Jonathan Wight on 07/12/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import <UIKit/UIKit.h>

@interface CCoreTextLabel : UIView

@property (readwrite, nonatomic, strong) NSAttributedString *text;
@property (readwrite, nonatomic, strong) UIFont *font;                  // default is nil (system font 17 plain)
@property (readwrite, nonatomic, strong) UIColor *textColor;            // default is nil (text draws black)
@property (readwrite, nonatomic, assign) UITextAlignment textAlignment; // default is UITextAlignmentLeft
@property (readwrite, nonatomic, assign) UILineBreakMode lineBreakMode; // default is UILineBreakModeTailTruncation. used for single and multiple lines of text
@property (readwrite, nonatomic, assign) UILineBreakMode lastLineBreakMode; // default is UILineBreakModeTailTruncation. used for last line of text if different from lineBreakMode.
@property (readwrite, nonatomic, strong) UIColor *shadowColor;          // default is nil (no shadow)
@property (readwrite, nonatomic, assign) CGSize shadowOffset;           // default is CGSizeMake(0, -1) -- a top shadow
@property (readwrite, nonatomic, assign) CGFloat shadowBlurRadius;      // default is 0 (sharp shadow)
@property (readwrite, nonatomic, strong) UIColor *highlightedTextColor; // default is nil
@property (readwrite, nonatomic, getter=isHighlighted) BOOL highlighted; // default is NO
@property (readwrite, nonatomic, getter=isEnabled) BOOL enabled; // default is YES. changes how the label is drawn

@property (readwrite, nonatomic, assign) UIEdgeInsets insets;

+ (CGSize)sizeForString:(NSAttributedString *)inString font:(UIFont *)inBaseFont alignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode contentInsets:(UIEdgeInsets)inContentInsets thatFits:(CGSize)inSize;

- (CGSize)sizeForString:(NSAttributedString *)inText constrainedToSize:(CGSize)inSize;

- (NSArray *)rectsForRange:(NSRange)inRange;
- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint effectiveRange:(NSRange *)outRange;

@end

#pragma mark -

@class CCoreTextRenderer;

@interface CCoreTextLabel (CCoreTextLabel_PrivateExtensions)
@property (readonly, nonatomic, strong) CCoreTextRenderer *renderer;
+ (Class)rendererClass;
@end

