/*
 ARKippsterActivity.h
 
 Copyright (c) 2013 Alex Robinson
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>

/* This activity takes an NSURL and optionally an NSString as its activity items.
 *
 * 1. NSURL (required)
 *      This is the URL that you want to be saved to Kippt via Kippster.
 * 2. NSString (optional)
 *      This will be the title for the clip.
 *
 * If there are multiple strings and multiple URLs, only the last of each will be used.
 */

@interface ARKippsterActivity : UIActivity

/* The URL to callback to when Kippster has finished adding a clip.
    Empty by default. Either set this in the initializer, or this property. */
@property (strong, nonatomic) NSURL *callbackURL;

/* The text to be displayed on the back button in Kippster to cancel and go back to your app.
    Uses the "CFBundleName" from your Info.plist by default, which is usually what you'd want. */
@property (strong, nonatomic) NSString *callbackSource;

/* The text beneath the icon.
    Defaults to "Kippster". */
@property (strong, nonatomic) NSString *activityTitle;

// Use this initializer as a shortcut for setting the callbackURL.
- (id)initWithCallbackURL:(NSURL *)callbackURL;

@end
