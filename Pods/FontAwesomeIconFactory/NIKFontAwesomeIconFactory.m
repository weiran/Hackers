#import "NIKFontAwesomeIconFactory.h"

#import "NIKFontAwesomePathFactory.h"
#import "NIKFontAwesomePathRenderer.h"

#if TARGET_OS_IPHONE
typedef UIBezierPath NIKBezierPath;
#else
typedef NSBezierPath NIKBezierPath;
#endif

@implementation NIKFontAwesomeIconFactory

- (id)init {
    self = [super init];
    if (self) {
        _size = 32.0;
        _padded = YES;
        _colors = @[[NIKColor darkGrayColor]];
        _strokeColor = [NIKColor blackColor];
        _strokeWidth = 0.0;
    }
    return self;
}

- (void)setColors:(NSArray *)colors {
    _colors = [colors copy];
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (self.renderingMode == UIImageRenderingModeAutomatic) {
        self.renderingMode = UIImageRenderingModeAlwaysOriginal;
    }
#endif
}

#pragma mark - copy

- (id)copyWithZone:(NSZone *)zone {
    NIKFontAwesomeIconFactory *copy = [[[self class] allocWithZone:zone] init];
    if (copy != nil) {
        copy.size = self.size;
        copy.edgeInsets = self.edgeInsets;
        copy.colors = self.colors;
        copy.strokeColor = self.strokeColor;
        copy.strokeWidth = self.strokeWidth;
    }
    return copy;
}

- (NIKImage *)createImageForIcon:(NIKFontAwesomeIcon)icon {
    CGPathRef path = [self createPath:icon];
    NIKImage *image = [self createImageWithPath:path];
    CGPathRelease(path);
    return image;
}

- (CGPathRef)createPath:(NIKFontAwesomeIcon)icon CF_RETURNS_RETAINED {
    CGFloat paddedSize = _size - _strokeWidth;
    CGFloat width = _square ? paddedSize : CGFLOAT_MAX;
    return [[NIKFontAwesomePathFactory new] createPathForIcon:icon
                                                       height:paddedSize
                                                     maxWidth:width];
}

- (NIKImage *)createImageWithPath:(CGPathRef)path {
    CGRect bounds = CGPathGetBoundingBox(path);
    CGSize imageSize = bounds.size;
    CGPoint offset = CGPointZero;

    if (_padded) {
        imageSize.height = _size;
        imageSize.width += _strokeWidth;
    } else {
        // remove padding
        offset.x = -bounds.origin.x;
        offset.y = -bounds.origin.y;
        if (imageSize.height > _size) {
            // NIKFontAwesomeIconSun and NIKFontAwesomeIconLinux
            imageSize.height = _size;
        }
    }

    imageSize = [self roundImageSize:imageSize];

    if (_square) {
        CGFloat diff = imageSize.height - imageSize.width;
        if (diff > 0) {
            offset.x += .5 * diff;
            imageSize.width = imageSize.height;
        } else {
            offset.y += .5 * -diff;
            imageSize.height = imageSize.width;
        }
    };

    CGFloat padding = _strokeWidth * .5;
    offset.x += padding + _edgeInsets.left;
    offset.y += padding + _edgeInsets.bottom;
    imageSize.width += _edgeInsets.left + _edgeInsets.right;
    imageSize.height += _edgeInsets.top + _edgeInsets.bottom;

    NIKFontAwesomePathRenderer *renderer = [self createRenderer:path];
    renderer.offset = offset;

#if TARGET_OS_IPHONE
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, imageSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [renderer renderInContext:context];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([image respondsToSelector:@selector(renderingMode)]) {
        if (image.renderingMode != _renderingMode) {
            image = [image imageWithRenderingMode:_renderingMode];
        }
    }
#endif
    return image;

#else

    if ([NSImage respondsToSelector:@selector(imageWithSize:flipped:drawingHandler:)]) {
        return [NSImage imageWithSize:imageSize
                              flipped:NO
                       drawingHandler:^(CGRect rect) {
                           NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
                           [renderer renderInContext:[graphicsContext graphicsPort]];
                           return YES;
                       }];
    } else {
        NSImage *image = [[NSImage alloc] initWithSize:imageSize];
        [image lockFocus];
        NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
        [renderer renderInContext:[graphicsContext graphicsPort]];
        [image unlockFocus];
        return image;
    }
#endif
}

- (CGSize)roundImageSize:(CGSize)size {
    // Prevent +1 on values that are slightly too big (e.g. 24.000001).
    static const float EPSILON = 0.01;
    return CGSizeMake(ceil(size.width - EPSILON), ceil(size.height - EPSILON));
}

- (NIKFontAwesomePathRenderer *)createRenderer:(CGPathRef)path {
    NIKFontAwesomePathRenderer *renderer = [NIKFontAwesomePathRenderer new];
    renderer.path = path;

    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:_colors.count];
    for (NIKColor *color in _colors) {
        CGColorRef cgColor = copyCGColor(color);
        [colors addObject:(__bridge id) cgColor];
        CGColorRelease(cgColor);
    }
    renderer.colors = colors;
    CGColorRef cgColor = copyCGColor(_strokeColor);
    renderer.strokeColor = cgColor;
    CGColorRelease(cgColor);
    renderer.strokeWidth = _strokeWidth;

    return renderer;
}

CF_RETURNS_RETAINED
static CGColorRef copyCGColor(NIKColor *color) {
    CGColorRef cgColor;
#if TARGET_OS_IPHONE
    cgColor = CGColorCreateCopy(color.CGColor);
#else
    if ([color respondsToSelector:@selector(CGColor)]) {
        cgColor = CGColorCreateCopy(color.CGColor);
    } else {
        NSColor *deviceColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
        CGFloat components[4];
        [deviceColor getComponents:components];

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        cgColor = CGColorCreate(colorSpace, components);
        CGColorSpaceRelease(colorSpace);
    }
#endif
    return cgColor;
}

@end
