//
//  CLinkingCoreTextLabel.m
//  CoreText
//
//  Created by Jonathan Wight on 1/18/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CLinkingCoreTextLabel.h"

#import "CMarkupValueTransformer.h"
#import "NSAttributedString_Extensions.h"

@interface CLinkingCoreTextLabel ()
@property (readwrite, nonatomic, strong) NSArray *linkRanges;
@end

#pragma mark -

@implementation CLinkingCoreTextLabel

@synthesize linkRanges;
@synthesize URLHandler;
@synthesize tapRecognizer;

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.enabled = NO;
        [self addGestureRecognizer:self.tapRecognizer];
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.enabled = NO;
        [self addGestureRecognizer:self.tapRecognizer];
        }
    return(self);
    }

- (void)setText:(NSAttributedString *)inText
    {
    if (self.text != inText)
        {
        [super setText:inText];
        
        NSMutableArray *theRanges = [NSMutableArray array];
        [self.text enumerateAttribute:kMarkupLinkAttributeName inRange:(NSRange){ .length = self.text.length } options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value != NULL)
                {
                [theRanges addObject:[NSValue valueWithRange:range]];
                }
            }];
        self.linkRanges = [theRanges copy];

        self.tapRecognizer.enabled = self.linkRanges.count > 0;
        }
    }
    
- (void)setEnabled:(BOOL)inEnabled
    {
    [super setEnabled:inEnabled];
    
    self.tapRecognizer.enabled = inEnabled && self.linkRanges.count > 0;
    }
    
#pragma mark -

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];
    theLocation.x -= self.insets.left;
    theLocation.y -= self.insets.top;

    NSRange theRange;
    NSDictionary *theAttributes = [self attributesAtPoint:theLocation effectiveRange:&theRange];
    NSURL *theLink = [theAttributes objectForKey:kMarkupLinkAttributeName];
    if (theLink != NULL)
        {
        if (self.URLHandler != NULL)
            {
            self.URLHandler(theRange, theLink);
            }
        }
    }
    
@end
