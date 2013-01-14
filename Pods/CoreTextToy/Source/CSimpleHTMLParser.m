//
//  CSimpleHTMLParser.m
//  TouchCode
//
//  Created by Jonathan Wight on 07/15/11.
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

#import "CSimpleHTMLParser.h"

#import "NSScanner_HTMLExtensions.h"

NSString *const kSimpleHTMLParserErrorDomain = @"kSimpleHTMLParserErrorDomain";


@interface CSimpleHTMLParser ()
- (NSString *)stringForEntity:(NSString *)inEntity;
@end

@implementation CSimpleHTMLParser

@synthesize openTagHandler;
@synthesize closeTagHandler;
@synthesize textHandler;
@synthesize whitespaceCharacterSet;

- (id)init
	{
	if ((self = [super init]) != NULL)
		{
        openTagHandler = ^(CSimpleHTMLTag *tag, NSArray *tagStack) {};
        closeTagHandler = ^(CSimpleHTMLTag *tag, NSArray *tagStack) {};
        textHandler = ^(NSString *text, NSArray *tagStack) {};
        whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		}
	return(self);
	}

- (NSString *)stringForEntity:(NSString *)inEntity
    {
    static NSDictionary *sEntities = NULL;
    static dispatch_once_t sOnceToken;
    dispatch_once(&sOnceToken, ^{
        sEntities = [NSDictionary dictionaryWithObjectsAndKeys:
            @"\"", @"quot",
            @"&", @"amp",
            @"'", @"apos",
            @"<", @"lt",
            @">", @"gt",
            [NSString stringWithFormat:@"%C", (unichar)0xA0], @"nbsp",
            NULL];
        });

    NSString *theString = [sEntities objectForKey:inEntity];

    return(theString);
    }

- (BOOL)parseString:(NSString *)inString error:(NSError **)outError
    {
    @autoreleasepool
        {
        NSMutableCharacterSet *theCharacterSet = [self.whitespaceCharacterSet mutableCopy];
        [theCharacterSet addCharactersInString:@"<&"];
        [theCharacterSet invert];

        NSScanner *theScanner = [[NSScanner alloc] initWithString:inString];
        theScanner.charactersToBeSkipped = NULL;

        NSMutableArray *theTagStack = [NSMutableArray array];
        NSMutableString *theString = [NSMutableString string];

        BOOL theLastCharacterWasWhitespace = NO;

        while ([theScanner isAtEnd] == NO)
            {
            @autoreleasepool
                {
                NSString *theRun = NULL;
                NSString *theTagName = NULL;
                NSDictionary *theAttributes = NULL;

                if ([theScanner scanCloseTag:&theTagName] == YES)
                    {
                    CSimpleHTMLTag *theTag = [[CSimpleHTMLTag alloc] init];
                    theTag.name = theTagName;
                    
                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[theString characterAtIndex:theString.length - 1]];
                        self.textHandler(theString, theTagStack);
                        }
                    theString = [NSMutableString string];

                    self.closeTagHandler(theTag, theTagStack);

                    NSUInteger theIndex = [theTagStack indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) { return([[obj name] isEqualToString:theTagName]); }];
                    if (theIndex == NSNotFound)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Stack underflow", NSLocalizedDescriptionKey,
                                NULL];
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_StackUnderflow userInfo:theUserInfo];
                            }
                        return(NO);
                        }

                    [theTagStack removeObjectsInRange:(NSRange){ .location = theIndex, .length = theTagStack.count - theIndex }];
                    }
                else if ([theScanner scanOpenTag:&theTagName attributes:&theAttributes] == YES)
                    {
                    CSimpleHTMLTag *theTag = [[CSimpleHTMLTag alloc] init];
                    theTag.name = theTagName;
                    theTag.attributes = theAttributes;

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = NO;
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    if ([theTagName isEqualToString:@"br"])
                        {
                        theLastCharacterWasWhitespace = YES;
                        self.textHandler(@"\n", theTagStack);
                        theString = [NSMutableString string];
                        }
                    else
                        {
                        self.openTagHandler(theTag, theTagStack);

                        [theTagStack addObject:theTag];
                        }
                    }
                else if ([theScanner scanStandaloneTag:&theTagName attributes:&theAttributes] == YES)
                    {
                    CSimpleHTMLTag *theTag = [[CSimpleHTMLTag alloc] init];
                    theTag.name = theTagName;
                    theTag.attributes = theAttributes;

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = NO;
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    if ([theTagName isEqualToString:@"br"])
                        {
                        theLastCharacterWasWhitespace = YES;
                        self.textHandler(@"\n", theTagStack);
                        theString = [NSMutableString string];
                        }
                    else
                        {
                        self.openTagHandler(theTag, theTagStack);
                        self.closeTagHandler(theTag, theTagStack);
                        }
                    }
                else if ([theScanner scanString:@"&" intoString:NULL] == YES)
                    {
                    NSString *theEntity = NULL;
                    if ([theScanner scanUpToString:@";" intoString:&theEntity] == NO)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"& not followed by ;", NSLocalizedDescriptionKey,
                                NULL];
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_MalformedEntity userInfo:theUserInfo];
                            }
                        return(NO);
                        }
                    if ([theScanner scanString:@";" intoString:NULL] == NO)
                        {
                        if (outError)
                            {
                            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"& not followed by ;", NSLocalizedDescriptionKey,
                                NULL];
                            *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_MalformedEntity userInfo:theUserInfo];
                            }
                        return(NO);
                        }

                    if (theString.length > 0)
                        {
                        theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];
                        self.textHandler(theString, theTagStack);
                        theString = [NSMutableString string];
                        }

                    NSString *theEntityString = [self stringForEntity:theEntity];
                    if (theEntityString.length > 0)
                        {
                        self.textHandler(theEntityString, theTagStack);
                        theLastCharacterWasWhitespace = NO;
                        }
                    }
                else if ([theScanner scanCharactersFromSet:self.whitespaceCharacterSet intoString:NULL])
                    {
                    if (theLastCharacterWasWhitespace == NO)
                        {
                        [theString appendString:@" "];
                        theLastCharacterWasWhitespace = YES;
                        }
                    }
                else if ([theScanner scanCharactersFromSet:theCharacterSet intoString:&theRun])
                    {
                    [theString appendString:theRun];
                    theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];
                    }
                else
                    {
                    if (outError)
                        {
                        NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"Unknown error occured!", NSLocalizedDescriptionKey,
                            [NSNumber numberWithInt:theScanner.scanLocation], @"character",
                            inString, @"markup",
                            NULL];
                        *outError = [NSError errorWithDomain:kSimpleHTMLParserErrorDomain code:kSimpleHTMLParserErrorCode_UnknownError userInfo:theUserInfo];
                        }
                    return(NO);
                    }
                }
            }

        if (theString.length > 0)
            {
            theLastCharacterWasWhitespace = [self.whitespaceCharacterSet characterIsMember:[theString characterAtIndex:theString.length - 1]];
            self.textHandler(theString, theTagStack);
            }
        }
        
    return(YES);
    }

@end

#pragma mark - 

@implementation CSimpleHTMLTag

@synthesize name;
@synthesize attributes;

@end