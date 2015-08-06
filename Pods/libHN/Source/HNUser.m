// Copyright (C) 2013 by Benjamin Gordon
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and
// associated documentation files (the "Software"), to
// deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "HNUser.h"
#import "HNUtilities.h"
#import "HNManager.h"

@implementation HNUser

#pragma mark - New User from an HTML response
+(HNUser *)userFromHTML:(NSString *)html {
    // Make a new user
    HNUser *newUser = [HNUser new];
    newUser.Username = @"Unknown User";
    newUser.Age = 0;
    newUser.AboutInfo = @"N/A";
    
    // Scan HTML into strings
    NSString *trash=@"";
    NSDictionary *jsonDict = [[HNManager sharedManager] JSONConfiguration];
    NSDictionary *userDict = jsonDict && jsonDict[@"User"] ? jsonDict[@"User"] : nil;
    if (!userDict || !userDict[@"Parts"]) {
        return newUser;
    }
    
    NSMutableDictionary *uDict = [NSMutableDictionary new];
    NSScanner *scanner = [NSScanner scannerWithString:html];
    for (NSDictionary *dict in userDict[@"Parts"]) {
        NSString *new = @"";
        BOOL isTrash = [dict[@"I"] isEqualToString:@"TRASH"];
        [scanner scanBetweenString:dict[@"S"] andString:dict[@"E"] intoString:isTrash ? &trash : &new];
        if (new.length > 0) {
            [uDict setObject:new forKey:dict[@"I"]];
        }
    }
    
    // Set Values
    newUser.Username = uDict[@"user"] ? uDict[@"user"] : newUser.Username;
    newUser.Age = uDict[@"age"] ? [uDict[@"age"] intValue] : newUser.Age;
    newUser.Karma = uDict[@"karma"] ? [uDict[@"karma"] intValue] : newUser.Karma;
    newUser.AboutInfo = uDict[@"about"] ? uDict[@"about"] : newUser.AboutInfo;
    
    return newUser;
}


@end
