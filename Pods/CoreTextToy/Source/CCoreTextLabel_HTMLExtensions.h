//
//  CCoreTextLabel+CCoreTextLabel_HTMLExtensions.h
//  knotes
//
//  Created by Jonathan Wight on 10/27/11.
//  Copyright (c) 2011 knotes. All rights reserved.
//

#import "CCoreTextLabel.h"

@class CMarkupValueTransformer;

@interface CCoreTextLabel (CCoreTextLabel_HTMLExtensions)

@property (readwrite, nonatomic, strong) CMarkupValueTransformer *markupValueTransformer;
@property (readwrite, nonatomic, strong) NSString *markup;

@end
