#import "_WZPost.h"

@interface WZPost : _WZPost {}

@property (nonatomic) CGFloat cellHeight;
@property (nonatomic) CGFloat labelHeight;

- (void)updateAttributes:(NSDictionary *)attributes;

@end
