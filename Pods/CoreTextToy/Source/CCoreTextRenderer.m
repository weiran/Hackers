//
//  CCoreTextRenderer.m
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextRenderer.h"

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "CCoreTextAttachment.h"
#import "NSAttributedString_Extensions.h"

@interface CCoreTextRenderer ()
@property (readwrite, nonatomic, strong) NSMutableDictionary *prerenderersForAttributes;
@property (readwrite, nonatomic, strong) NSMutableDictionary *postRenderersForAttributes;
@property (readwrite, nonatomic, assign) BOOL enableShadowRenderer;

@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, assign) CTFrameRef frame;
@property (readwrite, nonatomic, assign) CGPoint *lineOrigins;
@property (readwrite, nonatomic, strong) NSMutableData *lineOriginsData;

- (void)reset;

@end

#pragma mark -

@implementation CCoreTextRenderer

@synthesize text;
@synthesize size;

@synthesize prerenderersForAttributes;
@synthesize postRenderersForAttributes;
@synthesize enableShadowRenderer;

@synthesize framesetter;
@synthesize frame;
@synthesize lineOrigins;
@synthesize lineOriginsData;

+ (CGSize)sizeForString:(NSAttributedString *)inString thatFits:(CGSize)inSize
    {
    CTFramesetterRef theFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)inString);
    if (theFramesetter == NULL)
        {
        NSLog(@"Could not create CTFramesetter");
        return(CGSizeZero);
        }

    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(theFramesetter, (CFRange){}, NULL, inSize, NULL);
    CFRelease(theFramesetter);
    
    if (inSize.width < CGFLOAT_MAX && inSize.height == CGFLOAT_MAX)
        {
        theSize.width = inSize.width;
        }
    
    // On iOS 5.0 the function `CTFramesetterSuggestFrameSizeWithConstraints` returns rounded float values (e.g. "15.0").
    // Prior to iOS 5.0 the function returns float values (e.g. "14.7").
    // Make sure the return value for `sizeForString:thatFits:" is equal for both versions:
    theSize = (CGSize){ .width = roundf(theSize.width), .height = roundf(theSize.height) };
        
    return(theSize);
    }

#pragma mark -

- (id)initWithText:(NSAttributedString *)inText size:(CGSize)inSize
    {
    if ((self = [super init]) != NULL)
        {
        text = [inText copy];
        size = inSize;
        enableShadowRenderer = NO;
        
        [text enumerateAttribute:kShadowColorAttributeName inRange:(NSRange){ .length = text.length } options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            enableShadowRenderer = YES;
            *stop = YES;
            }];
        }
    return(self);
    }

- (void)dealloc
    {
    if (frame)
        {
        CFRelease(frame);
        frame = NULL;
        }

    if (framesetter)
        {
        CFRelease(framesetter);
        framesetter = NULL;
        }
    }

#pragma mark -

- (CTFramesetterRef)framesetter
    {
    if (framesetter == NULL && self.text != NULL)
        {
        framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.text);
        if (framesetter == NULL)
            {
            NSLog(@"Could not create CTFramesetter");
            }
        }
    return(framesetter);
    }

- (CTFrameRef)frame
    {
    if (frame == NULL && self.text != NULL)
        {
        CGPathRef thePath = CGPathCreateWithRect((CGRect){ .size = self.size }, NULL);

        frame = CTFramesetterCreateFrame(self.framesetter, (CFRange){}, thePath, NULL);

        if (frame == NULL)
            {
            NSLog(@"Could not create CTFrameRef");
            }
            
        CFRelease(thePath);
        }
    return(frame);
    }
    
- (void)setText:(NSAttributedString *)inText
    {
    if (text != inText)
        {
        text = [inText copy];
    
        [self reset];
        }
    }
    
- (void)setSize:(CGSize)inSize
    {
    size = inSize;
    
    [self reset];    
    }
    
- (CGPoint *)lineOrigins
    {
    if (lineOriginsData == NULL)
        {
        NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(self.frame);

        lineOriginsData = [NSMutableData dataWithLength:sizeof(CGPoint) * theLines.count];
        CTFrameGetLineOrigins(self.frame, (CFRange){}, [lineOriginsData mutableBytes]); 
        }
    return([lineOriginsData mutableBytes]);
    }

#pragma mark -

- (void)addPrerendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
    {
    if (self.prerenderersForAttributes == NULL)
        {
        self.prerenderersForAttributes = [NSMutableDictionary dictionary];
        }
        
    [self.prerenderersForAttributes setObject:[inBlock copy] forKey:inKey];
    }

- (void)addPostRendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
    {
    if (self.postRenderersForAttributes == NULL)
        {
        self.postRenderersForAttributes = [NSMutableDictionary dictionary];
        }
        
    [self.postRenderersForAttributes setObject:[inBlock copy] forKey:inKey];
    }

#pragma mark -

- (CGSize)sizeThatFits:(CGSize)inSize
    {
    if (inSize.width == 0.0 && inSize.height == 0.0)
        {
        inSize.width = CGFLOAT_MAX;
        inSize.height = CGFLOAT_MAX;
        }
    
    CFRange theFitRange;
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){}, NULL, inSize, &theFitRange);

    theSize.width = roundf(MIN(theSize.width, inSize.width));
    theSize.height = roundf(MIN(theSize.height, inSize.height));

    return(theSize);
    }

- (void)drawInContext:(CGContextRef)inContext
    {
    if (self.text.length == 0)
        {
        return;
        }
    
    // ### Get and set up the context...
    CGContextSaveGState(inContext);

    CGContextScaleCTM(inContext, 1.0, -1.0);
    CGContextTranslateCTM(inContext, 0, -self.size.height);

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.prerenderersForAttributes.count > 0)
        {
        [self enumerateRuns:^(CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.prerenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(inContext, inRun, inRect);
                    }
                }];
            }];
        }

    // ### Reset the text position (important!)
    CGContextSetTextPosition(inContext, 0, 0);

    // ### Render the text...
    if (self.enableShadowRenderer == NO)
        {
        CTFrameDraw(self.frame, inContext);
        }
    else
        {
        const CGPoint *theLineOrigins = self.lineOrigins;

        [self enumerateLines:^(CTLineRef line, NSUInteger idx, BOOL *stop) {
            // ### Get the line rect offseting it by the line origin
            const CGPoint theLineOrigin = theLineOrigins[idx];

            CGContextSetTextPosition(inContext, theLineOrigin.x, theLineOrigin.y);
            
            // ### Iterate each run... Keeping track of our X position...
            NSArray *theRuns = (__bridge NSArray *)CTLineGetGlyphRuns(line);
            [theRuns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

                CTRunRef theRun = (__bridge CTRunRef)obj;

                // TODO: Optimisation instead of constantly saving/restoring state and setting shadow we can keep track of current shadow and only save/restore/set when there's a change.
                NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(theRun);
                CGColorRef theShadowColor = (__bridge CGColorRef)[theAttributes objectForKey:kShadowColorAttributeName];
                CGSize theShadowOffset = CGSizeZero;
                NSValue *theShadowOffsetValue = [theAttributes objectForKey:kShadowOffsetAttributeName];
                if (theShadowColor != NULL && theShadowOffsetValue != NULL)
                    {
                    theShadowOffset = [theShadowOffsetValue CGSizeValue];

                    CGFloat theShadowBlurRadius = [[theAttributes objectForKey:kShadowBlurRadiusAttributeName] floatValue];

                    CGContextSaveGState(inContext);
                    CGContextSetShadowWithColor(inContext, theShadowOffset, theShadowBlurRadius, theShadowColor);
                    }

                // Render!
                CTRunDraw(theRun, inContext, (CFRange){});

                // Restore state if we were in a shadow
                if (theShadowColor != NULL && theShadowOffsetValue != NULL)
                    {
                    CGContextRestoreGState(inContext);
                    }

                }];

            }];
        
        }

    // ### Reset the text position (important!)
    CGContextSetTextPosition(inContext, 0, 0);

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.postRenderersForAttributes.count > 0)
        {
        [self enumerateRuns:^(CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.postRenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(inContext, inRun, inRect);
                    }
                }];
            }];
        }

    CGContextRestoreGState(inContext);

    // ### Now that the CTM is restored. Iterate through each line and render any attachments.
    [self enumerateRuns:^(CTRunRef inRun, CGRect inRect) {
        NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
        // ### If we have an image we draw it...
        CCoreTextAttachment *theAttachment = [theAttributes objectForKey:kMarkupAttachmentAttributeName];
        if (theAttachment != NULL)
            {
            inRect.origin.y *= -1;
            inRect.origin.y += self.size.height - inRect.size.height;

            theAttachment.renderer(theAttachment, inContext, inRect);
            }
        }];
    }

#pragma mark -

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint effectiveRange:(CFRange *)outRange
    {
    const NSUInteger theIndex = [self indexAtPoint:inPoint];
    if (theIndex == NSNotFound || theIndex >= self.text.length)
        {
        return(NULL);
        }
    else
        {
        NSDictionary *theAttributes = [self.text attributesAtIndex:theIndex effectiveRange:(NSRange *)outRange];
        return(theAttributes);
        }
    }
    
- (NSArray *)rectsForRange:(CFRange)inRange
    {
    NSMutableArray *theRects = [NSMutableArray array];

    [self enumerateRuns:^(CTRunRef inRun, CGRect inRect) {

//    NSIntersectionRange(inRange, 
    
        CFRange theRunRange = CTRunGetStringRange(inRun);
        if (theRunRange.location >= (CFIndex)inRange.location && theRunRange.location <= (CFIndex)inRange.location + (CFIndex)inRange.length)
            {
            inRect.origin.y *= -1;
            inRect.origin.y += self.size.height -  inRect.size.height;
            
            [theRects addObject:[NSValue valueWithCGRect:inRect]];
            }
        }];

    return(theRects);
    }
    
- (NSUInteger)indexAtPoint:(CGPoint)inPoint
    {
    inPoint.y *= -1;
    inPoint.y += self.size.height;

    __block CGPoint theLastLineOrigin = (CGPoint){ 0, CGFLOAT_MAX };
    __block NSUInteger theIndex = NSNotFound;

    [self enumerateLines:^(CTLineRef line, NSUInteger idx, BOOL *stop) {
        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(self.frame, CFRangeMake(idx, 1), &theLineOrigin);

        if (inPoint.y > theLineOrigin.y && inPoint.y < theLastLineOrigin.y)
            {
            theIndex = CTLineGetStringIndexForPosition(line, (CGPoint){ .x = inPoint.x - theLineOrigin.x, inPoint.y - theLineOrigin.y });
            if (theIndex != NSNotFound && (NSUInteger)theIndex < self.text.length)
                {
                *stop = YES;
                }
            }
        theLastLineOrigin = theLineOrigin;
        }];
        
    return(theIndex);
    }

- (NSArray *)visibleLines
    {
    NSMutableArray *theVisibleLines = [NSMutableArray array];
    
    [self enumerateLines:^(CTLineRef line, NSUInteger idx, BOOL *stop) {
        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(self.frame, CFRangeMake(idx, 1), &theLineOrigin);

        // TODO use CTLineGetTypographicBounds?
        if (theLineOrigin.y >= 0.0 && theLineOrigin.y <= self.size.height)
            {
            [theVisibleLines addObject:(__bridge id)line];
            }
        if (theLineOrigin.y > self.size.height)
            {
            *stop = YES;
            }
        }];
    
    return([theVisibleLines copy]);
    }

- (CFRange)rangeOfLastLine
    {
    CTLineRef theLine = (__bridge CTLineRef)[self.visibleLines lastObject];
    
    CFRange theRange = CTLineGetStringRange(theLine);
    
    return((CFRange){ .location = theRange.location, .length = theRange.length });
    }

- (void)enumerateLines:(void (^)(CTLineRef line, NSUInteger idx, BOOL *stop))inHandler
    {
    NSParameterAssert(inHandler != NULL);
    
    // ### Iterate through each line...
    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(self.frame);
    [theLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CTLineRef theLine = (__bridge CTLineRef)obj;
        inHandler(theLine, idx, stop);
        }];
    }

- (void)enumerateRuns:(void (^)(CTRunRef, CGRect))inHandler
    {
    NSParameterAssert(inHandler != NULL);

    // ### Iterate through each line...
    [self enumerateLines:^(CTLineRef line, NSUInteger idx, BOOL *stop) {
        // ### Get the line rect offseting it by the line origin
        const CGPoint theLineOrigin = self.lineOrigins[idx];
        
        // ### Iterate each run... Keeping track of our X position...
        __block CGFloat theXPosition = 0;
        NSArray *theRuns = (__bridge NSArray *)CTLineGetGlyphRuns(line);
        [theRuns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CTRunRef theRun = (__bridge CTRunRef)obj;
            
            // ### Get the ascent, descent, leading, width and produce a rect for the run...
            CGFloat theAscent, theDescent, theLeading;
            double theWidth = CTRunGetTypographicBounds(theRun, (CFRange){}, &theAscent, &theDescent, &theLeading);
            CGRect theRunRect = {
                .origin = { theLineOrigin.x + theXPosition, theLineOrigin.y },
                .size = { (CGFloat)theWidth, theAscent + theDescent },
                };

            inHandler(theRun, theRunRect);

            theXPosition += theWidth;
            }];
        }];
    }

#pragma mark -

- (void)reset
    {
    if (frame)
        {
        CFRelease(frame);
        self.frame = NULL;
        }

    if (framesetter)
        {
        CFRelease(framesetter);
        self.framesetter = NULL;
        }

    self.lineOrigins = NULL;
    self.lineOriginsData = NULL;
    }

@end
