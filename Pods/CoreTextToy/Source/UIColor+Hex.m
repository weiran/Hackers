//
//  UIColor+Hex.m
//  CultureShelf
//
//  Created by Daniel Wyszynski on 11/1/11.
//  Copyright (c) 2011 Punch Media, Inc. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (i7HexColor)

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    
	/* convert the string into a int */
	unsigned int colorValueR,colorValueG,colorValueB,colorValueA;
	NSString *hexStringCleared = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
	if(hexStringCleared.length == 3) {
		/* short color form */
		/* im lazy, maybe you have a better idea to convert from #fff to #ffffff */
		hexStringCleared = [NSString stringWithFormat:@"%@%@%@%@%@%@", [hexStringCleared substringWithRange:NSMakeRange(0, 1)],[hexStringCleared substringWithRange:NSMakeRange(0, 1)],
                            [hexStringCleared substringWithRange:NSMakeRange(1, 1)],[hexStringCleared substringWithRange:NSMakeRange(1, 1)],
                            [hexStringCleared substringWithRange:NSMakeRange(2, 1)],[hexStringCleared substringWithRange:NSMakeRange(2, 1)]];
	}
	if(hexStringCleared.length == 6) {
		hexStringCleared = [hexStringCleared stringByAppendingString:@"ff"];
	}
    
	/* im in hurry ;) */
	NSString *red = [hexStringCleared substringWithRange:NSMakeRange(0, 2)];
	NSString *green = [hexStringCleared substringWithRange:NSMakeRange(2, 2)];
	NSString *blue = [hexStringCleared substringWithRange:NSMakeRange(4, 2)];
	NSString *alpha = [hexStringCleared substringWithRange:NSMakeRange(6, 2)];
    
	[[NSScanner scannerWithString:red] scanHexInt:&colorValueR];
	[[NSScanner scannerWithString:green] scanHexInt:&colorValueG];
	[[NSScanner scannerWithString:blue] scanHexInt:&colorValueB];
	[[NSScanner scannerWithString:alpha] scanHexInt:&colorValueA];
    
    
	return [UIColor colorWithRed:((colorValueR)&0xFF)/255.0f 
                           green:((colorValueG)&0xFF)/255.0f 
                            blue:((colorValueB)&0xFF)/255.0f 
                           alpha:((colorValueA)&0xFF)/255.0f];
    
    
}

@end