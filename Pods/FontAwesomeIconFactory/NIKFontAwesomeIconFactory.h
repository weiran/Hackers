#import "NIKFontAwesomeIcon.h"

#if TARGET_OS_IPHONE
typedef UIEdgeInsets NIKEdgeInsets;
typedef UIColor NIKColor;
typedef UIImage NIKImage;
#else
typedef NSEdgeInsets NIKEdgeInsets;
typedef NSColor NIKColor;
typedef NSImage NIKImage;
#endif

/**
 * Creates images from Font Awesome glyphs.
 *
 * On Mountain Lion, the generated image is resolution-independent. The size and strokeWidth are
 * only relative to each other.
 *
 * "Font Awesome" (http://fortawesome.github.com/Font-Awesome/) must be part of the app bundle.
 **/
@interface NIKFontAwesomeIconFactory : NSObject<NSCopying, NSCopying, NSCopying>

/** The height in points of the created images. */
@property (nonatomic, assign) CGFloat size;

/** Additional padding added to the created images. */
@property (nonatomic, assign) NIKEdgeInsets edgeInsets;

@property (nonatomic, assign, getter=isPadded) BOOL padded;
/**
 * Create images to be square?
 *
 * If true, the icon is scaled to fit in a square of "size".
 * If false, "size" determines the icon's height.
 **/
@property (nonatomic, assign, getter=isSquare) BOOL square;

/**
 * Colors for the gradient filling the icon.
 *
 * Array of NSColor/UIColor.
 *
 * Default: dark gray
 */
@property (nonatomic, copy) NSArray *colors;

/**
 * Color for stroke around the icon.
 *
 * Default: black (but strokeWidth defaults to 0.0)
 */
@property (nonatomic, copy) NIKColor *strokeColor;

/**
 * Width for stroke around the icon.
 *
 * Default: 0.0
 */
@property (nonatomic, assign) CGFloat strokeWidth;

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
/**
 * Rendering mode for the created images.
 *
 * By default, iOS will determine if color information is retained when using the image in a
 * control.  Set this to UIImageRenderingModeAlwaysOriginal to always get color.
 *
 * Default: UIImageRenderingModeAutomatic
 */
@property(nonatomic, assign) UIImageRenderingMode renderingMode NS_AVAILABLE_IOS(7_0);
#endif

/** Create an NSImage/UIImage from an icon. */
- (NIKImage *)createImageForIcon:(NIKFontAwesomeIcon)icon;

@end
