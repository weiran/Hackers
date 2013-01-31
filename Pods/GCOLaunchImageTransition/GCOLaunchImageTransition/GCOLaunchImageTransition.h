//
//  GCOLaunchImageTransition.h
//  GCOLaunchImageTransition
//
//  Copyright (c) 2013, Michael Sedlaczek, Gone Coding, http://gonecoding.com
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//    * Neither the name of Michael Sedlaczek and/or Gone Coding nor the
//      names of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY Michael Sedlaczek ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL Michael Sedlaczek BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <UIKit/UIKit.h>

#define GCOLaunchImageTransitionNearInfiniteDelay DBL_MAX

extern NSString* const GCOLaunchImageTransitionHideNotification;

typedef enum GCOLaunchImageTransitionAnimationStyle_
{
   GCOLaunchImageTransitionAnimationStyleFade,
   GCOLaunchImageTransitionAnimationStyleZoomOut,
   GCOLaunchImageTransitionAnimationStyleZoomIn
} GCOLaunchImageTransitionAnimationStyle;

@interface GCOLaunchImageTransition : NSObject

// Create transition with a given style that begins immediately

+ (void)transitionWithDuration:(NSTimeInterval)duration style:(GCOLaunchImageTransitionAnimationStyle)style;

// Create transition with an near-infinite delay that requires manual dismissal via notification like this:
// [[NSNotificationCenter defaultCenter] postNotificationName:GCOLaunchImageTransitionHideNotification object:self];)

+ (void)transitionWithInfiniteDelayAndDuration:(NSTimeInterval)duration style:(GCOLaunchImageTransitionAnimationStyle)style;

// Create fully customizable transition including an optional activity indicator
// The 'activityIndicatorPosition' is a percentage value ('CGPointMake( 0.5, 0.5 )' being the center)
// See https://github.com/gonecoding/GCOLaunchImageTransition for more documentation

+ (void)transitionWithDelay:(NSTimeInterval)delay duration:(NSTimeInterval)duration style:(GCOLaunchImageTransitionAnimationStyle)style activityIndicatorPosition:(CGPoint)activityIndicatorPosition activityIndicatorStyle:(UIActivityIndicatorViewStyle)activityIndicatorStyle;

@end
