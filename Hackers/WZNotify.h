//
//  WZNotify.h
//  Hackers
//
//  Created by Weiran Zhang on 01/03/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WZNotify : UIView

+ (void)showMessage:(NSString *)message inView:(UIView *)view duration:(CGFloat)duration;

@end
