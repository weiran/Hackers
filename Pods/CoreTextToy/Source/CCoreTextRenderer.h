//
//  CCoreTextRenderer.h
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

@interface CCoreTextRenderer : NSObject

@property (readwrite, nonatomic, copy) NSAttributedString *text;
@property (readwrite, nonatomic, assign) CGSize size;

+ (CGSize)sizeForString:(NSAttributedString *)inString thatFits:(CGSize)size;

- (id)initWithText:(NSAttributedString *)inText size:(CGSize)inSize;

- (void)addPrerendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
- (void)addPostRendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;

- (CGSize)sizeThatFits:(CGSize)inSize;
- (void)drawInContext:(CGContextRef)inContext;

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint effectiveRange:(CFRange *)outRange;
- (NSArray *)rectsForRange:(CFRange)inRange;
- (NSUInteger)indexAtPoint:(CGPoint)inPoint;
- (NSArray *)visibleLines;
- (CFRange)rangeOfLastLine;

- (void)enumerateLines:(void (^)(CTLineRef line, NSUInteger idx, BOOL *stop))inHandler;
- (void)enumerateRuns:(void (^)(CTRunRef, CGRect))inHandler;

@end

#pragma mark -

@interface CCoreTextRenderer (CCoreTextRenderer_PrivateExtensions)
@property (readwrite, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, assign) CTFrameRef frame;
- (void)reset;
@end
