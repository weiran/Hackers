//
//  WZActivityView.h
//  Hackers
//
//  Created by Weiran Zhang on 02/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZActivityView : NSObject

+ (UIActivityViewController *)activitViewControllerWithUrl:(NSURL *)url text:(NSString *)text;

@end
