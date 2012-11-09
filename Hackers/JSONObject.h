//
//  JSONObject.h
//  Hackers
//
//  Created by Weiran Zhang on 05/11/2012.
//  Copyright (c) 2012 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONObject : NSObject

+ (id)objectWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)populateDictionary:(NSDictionary *)dictionary;
+ (NSString *)normalizedKey:(NSString *)inKey;

@end
