#import "NIKFontAwesomePathRenderer.h"

@implementation NIKFontAwesomePathRenderer

- (void)dealloc {
    self.path = NULL;
    self.strokeColor = NULL;
}

- (void)setPath:(CGPathRef)path {
    if (_path) {
        CGPathRelease(_path);
    }
    _path = path ? CGPathCreateCopy(path) : NULL;
}

- (void)setStrokeColor:(CGColorRef)strokeColor {
    if (_strokeColor) {
        CGColorRelease(_strokeColor);
    }
    _strokeColor = strokeColor ? CGColorCreateCopy(strokeColor) : NULL;
}

#pragma mark -

- (void)renderInContext:(CGContextRef)context {

    CGRect bounds = CGPathGetBoundingBox(_path);

    CGContextTranslateCTM(context, _offset.x, _offset.y);

    CGContextAddPath(context, _path);
    if (_colors.count > 1) {
        CGContextSaveGState(context);
        CGContextClip(context);
        [self renderGradientInRect:bounds context:context];
        CGContextRestoreGState(context);
    } else {
        CGContextSetFillColorWithColor(context, (__bridge CGColorRef)_colors[0]);
        CGContextFillPath(context);
    }

    CGContextAddPath(context, _path);
    if (_strokeColor && _strokeWidth > 0.0) {
        CGContextSetStrokeColorWithColor(context, _strokeColor);
        CGContextSetLineWidth(context, _strokeWidth);

        CGContextStrokePath(context);
    }
}

- (void)renderGradientInRect:(CGRect)rect
                     context:(CGContextRef)context {

    NSUInteger n = _colors.count;
    CGFloat locations[n];
    for (NSUInteger i = 0; i < n; i++) {
        locations[i] = (CGFloat)i / (n - 1);
    }

    CGGradientRef gradient =
        CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)_colors, locations);
    CGContextDrawLinearGradient(context, gradient, CGRectGetTopLeft(rect),
                                CGRectGetBottomLeft(rect), 0);
    CGGradientRelease(gradient);
}

static CGPoint CGRectGetBottomLeft(CGRect rect) {
    return rect.origin;
}

static CGPoint CGRectGetTopLeft(CGRect rect) {
    return CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
}

@end
