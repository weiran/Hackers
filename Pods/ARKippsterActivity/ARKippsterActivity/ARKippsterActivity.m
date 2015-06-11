/*
 ARKippsterActivity.m
 
 Copyright (c) 2013 Alex Robinson
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ARKippsterActivity.h"

@implementation ARKippsterActivity {
    // Set via prepareWithActivityItems:
	NSURL *_linkURL; // The URL that will be saved.
    NSString *_linkTitle; // The Title that should be set.
}

@synthesize callbackURL = _callbackURL;
@synthesize callbackSource = _callbackSource;
@synthesize activityTitle = _activityTitle;

- (void)commonInit {
    // Set the property defaults.
    _callbackSource = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleName"];
    _activityTitle = @"Kippster";
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCallbackURL:(NSURL *)callbackURL {
    self = [super init];
    if (self) {
        [self commonInit];
        _callbackURL = callbackURL;
    }
    return self;
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"kippster-activity"];
}

- (NSString *)activityTitle {
    return _activityTitle;
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"kippster://"]];
    
    // Check whether there's a URL somewhere in activityItems.
    BOOL containsURL = NO;
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            containsURL = YES;
        }
    }
	return canOpenURL && containsURL;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            _linkURL = item;
        }
        else if ([item isKindOfClass:[NSString class]]) {
            _linkTitle = item;
        }
    }
}

- (void)performActivity {
	NSString *urlString = [NSString stringWithFormat:@"kippster://x-callback-url/add?url=%@&title=%@&x-success=%@&x-error=%@&x-cancel=%@&x-source=%@",
                           [_linkURL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [_linkTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [_callbackURL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [_callbackURL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           [_callbackURL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                           _callbackSource];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
	[self activityDidFinish:YES];
}

@end
