//
//  JSONObject.m
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import "JSONObject.h"
#import "NSString+NamingConventions.h"

@implementation JSONObject

+ (id)objectWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self populateDictionary:dictionary];
    }
    
    return self;
}

- (void)populateDictionary:(NSDictionary *)dictionary {
    for (NSString *key in [dictionary allKeys]) {
        NSString *normalizedKey = [JSONObject normalizedKey:key];
        NSArray *setterComponents = @[@"set", normalizedKey];
        NSString *setterName = [[NSString camelCase:setterComponents] stringByAppendingString:@":"];
        SEL setterSelector = NSSelectorFromString(setterName);
        if ([self respondsToSelector:setterSelector]) {
            id value = [dictionary objectForKey:key];
            [self setValue:value forSelector:setterSelector];
        }
    }
}

- (void)setValue:(id)value forSelector:(SEL)selector {
#       pragma clang diagnostic push
#       pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:selector withObject:value];
#       pragma clang diagnostic pop
}

+ (NSString *)normalizedKey:(NSString *)inKey {
    NSArray *components = [inKey componentsSeparatedByString:@"_"];
    return [NSString camelCase:components];
}


@end
