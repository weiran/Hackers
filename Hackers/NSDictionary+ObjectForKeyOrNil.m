//
//  NSDictionary+ObjectForKeyOrNil.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "NSDictionary+ObjectForKeyOrNil.h"

@implementation NSDictionary (ObjectForKeyOrNil)

- (id)objectForKeyOrNil:(id)key {
    id val = [self objectForKey:key];
    if ([val isEqual:[NSNull null]]) {
        return nil;
    }
    
    return val;
}

@end
