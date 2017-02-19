#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "HNComment.h"
#import "HNCommentLink.h"
#import "HNManager.h"
#import "HNPost.h"
#import "HNUser.h"
#import "HNUtilities.h"
#import "HNWebService.h"
#import "libHN.h"

FOUNDATION_EXPORT double libHNVersionNumber;
FOUNDATION_EXPORT const unsigned char libHNVersionString[];

