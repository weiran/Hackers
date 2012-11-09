#import "WZComment.h"

#import "NSDictionary+ObjectForKeyOrNil.h"

@implementation WZComment

- (void)updateAttributes:(NSDictionary *)attributes {
    self.content = [attributes objectForKeyOrNil:@"content"];
    self.id = [attributes objectForKeyOrNil:@"id"];
    self.level = [attributes objectForKeyOrNil:@"level"];
    self.timeAgo = [attributes objectForKeyOrNil:@"time_ago"];
    self.user = [attributes objectForKeyOrNil:@"user"];
}

@end
