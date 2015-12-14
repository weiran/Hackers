/** Renders a path using a CGContext. */
@interface NIKFontAwesomePathRenderer : NSObject

@property (nonatomic, assign) CGPathRef path;
@property (nonatomic, assign) CGPoint offset;

@property (nonatomic, copy) NSArray *colors;
@property (nonatomic, assign) CGColorRef strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;

- (void)renderInContext:(CGContextRef)context;

@end
