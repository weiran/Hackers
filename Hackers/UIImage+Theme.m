//
//  UIImage+Theme.m
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import "UIImage+Theme.h"

@implementation UIImage (Theme)

+ (UIImage *)themeImageNamed:(NSString *)name {
    UIImage *image;
    
    if ([WZTheme darkTheme]) {
        image = [UIImage imageNamed:[name stringByAppendingString:@"-darktheme"]];
    }

    if (!image) {
        image = [UIImage imageNamed:[name stringByAppendingString:@"-lighttheme"]];
        
        if (!image) {
            image = [UIImage imageNamed:name];
        }
    }

    return image;
}

@end
