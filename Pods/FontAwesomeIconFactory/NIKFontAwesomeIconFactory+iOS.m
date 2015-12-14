#if TARGET_OS_IPHONE

#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"

@implementation NIKFontAwesomeIconFactory(iOS)

+ (instancetype)buttonIconFactory {
    NIKFontAwesomeIconFactory *factory = [self textlessButtonIconFactory];
    factory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 8.0);
    return factory;
}

+ (instancetype)textlessButtonIconFactory {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory new];
    factory.size = 16.0;
    return factory;
}

+ (instancetype)barButtonItemIconFactory {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory new];
    factory.colors = @[[UIColor whiteColor]];
    factory.size = 22.0;
    return factory;
}

+ (instancetype)tabBarItemIconFactory {
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory new];
    factory.size = 24.0;
    factory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    return factory;
}

@end

#endif
