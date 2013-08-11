//
//  WZActivityViewController.h
//  Hackers
//
//  Created by Weiran Zhang on 05/02/2013.
//  Copyright (c) 2013 Weiran Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NNNetwork.h"

@interface WZActivityViewController : UIActivityViewController <UIAlertViewDelegate>

@property (nonatomic, copy) NSURL *url;

+ (WZActivityViewController *)activityViewControllerWithUrl:(NSURL *)url text:(NSString *)text;

@end
