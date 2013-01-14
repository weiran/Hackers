//
//  NSString_HTMLExtensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 9/22/11.
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
//  THIS SOFTWARE IS PROVIDED BY 2011 TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 2011 TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of 2011 toxicsoftware.com.

#import "NSString_HTMLExtensions.h"

@implementation NSString (NSString_HTMLExtensions)

- (NSString *)stringByLinkifyingString
    {
    NSError *theError = NULL;
    NSDataDetector *theDataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&theError];

    NSMutableString *theReplacementString = [NSMutableString string];

    __block NSRange theLastRange = { .length = 0 };

    [theDataDetector enumerateMatchesInString:self options:NSMatchingCompleted range:(NSRange){ .length = self.length } usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {

        NSRange theRange = result.range;
        if (theRange.length > 0)
            {
            NSString *theString = [self substringWithRange:(NSRange){ .location = theLastRange.location + theLastRange.length, theRange.location - theLastRange.location + theLastRange.length }];
            [theReplacementString appendString:theString];

            NSURL *theURL = result.URL;
            theString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", theURL.absoluteURL, theURL.absoluteURL];
            [theReplacementString appendString:theString];
            }
        else
            {
            NSString *theString = [self substringFromIndex:theLastRange.location + theLastRange.length];
            [theReplacementString appendString:theString];
            }

        theLastRange = theRange;
        }];

    return(theReplacementString);
    }

- (NSString *)stringByMarkingUpString
    {
    return([self stringByMarkingUpString:YES]);
    }

- (NSString *)stringByMarkingUpString:(BOOL)inLinkifyString
    {
    NSString *theString = [self stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    theString = [theString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    theString = [theString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    if (inLinkifyString == YES)
        {
        theString = [theString stringByLinkifyingString];
        }
    theString = [theString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    return(theString);
    }

@end
