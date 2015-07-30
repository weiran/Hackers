#import "NIKFontAwesomeIcon.h"

@interface NIKFontAwesomePathFactory : NSObject

- (CGPathRef)createPathForIcon:(NIKFontAwesomeIcon)icon
                        height:(CGFloat)height
                      maxWidth:(CGFloat)width CF_RETURNS_RETAINED;

@end
