//
//  CCoreTextAttachment.h
//  CoreText
//
//  Created by Jonathan Wight on 10/31/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

@interface CCoreTextAttachment : NSObject

@property (readwrite, nonatomic, assign) CGFloat ascent;
@property (readwrite, nonatomic, assign) CGFloat descent;
@property (readwrite, nonatomic, assign) CGFloat width;
@property (readwrite, nonatomic, copy) void (^renderer)(CCoreTextAttachment *, CGContextRef,CGRect);
@property (readwrite, nonatomic, strong) id representedObject;

- (id)initWithAscent:(CGFloat)inAscent descent:(CGFloat)inDescent width:(CGFloat)inWidth representedObject:(id)inRepresentedObject renderer:(void (^)(CCoreTextAttachment *,CGContextRef,CGRect))inRenderer;

- (CTRunDelegateRef)createRunDelegate;

@end
