//
//  NSString+NamingConventions.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "NSString+NamingConventions.h"

@implementation NSString (NamingConventions)

+ (NSString *)camelCase:(NSArray *)components {
    NSMutableString *result = [NSMutableString string];
    for (NSString *segment in components) {
        BOOL lowercase = [result length] == 0;
        if ([segment length] == 0) {
            continue;
        }
        
        if (lowercase) {
            [result appendString:
             [[segment substringToIndex:1] lowercaseString]
             ];
            [result appendString:
             [segment substringFromIndex:1]
             ];
        } else {
            [result appendString:
             [[segment substringToIndex:1] uppercaseString]
             ];
            [result appendString:
             [segment substringFromIndex:1]
             ];
        }
    }
    return result;
}

@end
