#import "WZPost.h"

#import "NSDictionary+ObjectForKeyOrNil.h"

@implementation WZPost

@synthesize cellHeight = _cellHeight;
@synthesize labelHeight = _labelHeight;

- (void)updateAttributes:(NSDictionary *)attributes {
    self.commentsCount = [attributes objectForKeyOrNil:@"comments_count"];
    self.domain = [attributes objectForKeyOrNil:@"domain"];
    self.id = [NSNumber numberWithInt:[[attributes objectForKeyOrNil:@"id"] intValue]];
    self.points = [attributes objectForKeyOrNil:@"points"];
    self.timeAgo = [attributes objectForKeyOrNil:@"time_ago"];
    self.title = [attributes objectForKeyOrNil:@"title"];
    self.type = [attributes objectForKeyOrNil:@"type"];
    self.url = [attributes objectForKeyOrNil:@"url"];
    self.user = [attributes objectForKeyOrNil:@"user"];
}

@end
