//
//  CCoreTextLabel_HTMLExtensions.m
//  knotes
//
//  Created by Jonathan Wight on 10/27/11.
//  Copyright (c) 2011 knotes. All rights reserved.
//

#import "CCoreTextLabel_HTMLExtensions.h"

#import <objc/runtime.h>

#import "CMarkupValueTransformer.h"

@implementation CCoreTextLabel (CCoreTextLabel_HTMLExtensions)

static void *kMarkupValueTransformerKey;

- (CMarkupValueTransformer *)markupValueTransformer
    {
    CMarkupValueTransformer *theMarkupValueTransformer = objc_getAssociatedObject(self, &kMarkupValueTransformerKey);
    if (theMarkupValueTransformer == NULL)
        {
        theMarkupValueTransformer = [[CMarkupValueTransformer alloc] init];
        theMarkupValueTransformer.whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
        objc_setAssociatedObject(self, &kMarkupValueTransformerKey, theMarkupValueTransformer, OBJC_ASSOCIATION_RETAIN);
        }
    return(theMarkupValueTransformer);
    }
    
- (void)setMarkupValueTransformer:(CMarkupValueTransformer *)inMarkupValueTransformer
    {
    objc_setAssociatedObject(self, &kMarkupValueTransformerKey, inMarkupValueTransformer, OBJC_ASSOCIATION_RETAIN);
    }

- (NSString *)markup
    {
    // Yes. Nothing to do here.
    return(NULL);
    }

- (void)setMarkup:(NSString *)inMarkup
    {
    NSError *theError = NULL;
    NSAttributedString *theAttributedString = [self.markupValueTransformer transformedValue:inMarkup error:&theError];
    NSAssert1(theAttributedString != NULL, @"Could not transform HTML into attributed string: %@", theError);
    self.text = theAttributedString;
    }

@end
