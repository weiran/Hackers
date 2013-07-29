//
//  CLScrollView.m
//  Cascade
//
//  Created by Emil Wojtaszek on 26.07.2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CLScrollView.h"

@implementation CLScrollView

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        [self setClipsToBounds: NO];
        [self setDecelerationRate: UIScrollViewDecelerationRateFast];
        [self setScrollsToTop: NO];
        [self setBounces: YES];
        [self setAlwaysBounceVertical: NO];
        [self setAlwaysBounceHorizontal: YES];
        [self setDirectionalLockEnabled: YES];
        [self setDelaysContentTouches:YES];
        [self setMultipleTouchEnabled:NO];
        [self setShowsVerticalScrollIndicator: NO];
        [self setShowsHorizontalScrollIndicator: NO];

        [self setAutoresizingMask:
         UIViewAutoresizingFlexibleBottomMargin | 
         UIViewAutoresizingFlexibleTopMargin | 
         UIViewAutoresizingFlexibleHeight];

    }
    
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    // bug fix with auto scrolling when become first responder
    // do not overide it
}


@end
