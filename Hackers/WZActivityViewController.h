//
//  WZActivityViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WZActivityViewController : UIActivityViewController

+ (WZActivityViewController *)activityViewControllerWithUrl:(NSURL *)url text:(NSString *)text;

@end
